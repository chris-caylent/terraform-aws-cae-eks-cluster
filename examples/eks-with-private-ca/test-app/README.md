# How to test certs

This guide will provide the steps needed to verify your (self-signed) certificates are working on for your application.  This guide is not exhaustive, but you should be able to get an idea of how to apply it to other applications

Helpful [article](https://aws.amazon.com/blogs/containers/setting-up-end-to-end-tls-encryption-on-amazon-eks-with-the-new-aws-load-balancer-controller/) reference that walks through testing your certs using AWS PCA, however, we use cert-manager self-signed certs in this example.

* Once you have a cluster running you can use kubectl to apply the certificate and other K8S object manifests.  Be sure you have installed the cert-manager helm chart, this will ensure you have the root CA present in your cluster.

Resources will deploy to the default namespace.

```sh
cd eks-with-private-ca
kubectl apply -f test-app/manifests
```

* Verify your cert was created and issued

```sh
kubectl get certificate

NAME                READY   SECRET                AGE
test-app-tls-cert   True    test-app-crt-secret   7s
```

* Update the config map `secure-config` with the NLB DNS name located in: AWS Console --> EC2 --> Load Balancers

```sh
    kubectl edit cm secure-config
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: secure-config
data:
  app.conf: |-
    server {
      listen 8443 ssl proxy_protocol;
      real_ip_header proxy_protocol;
      set_real_ip_from 10.0.0.0/16;
      server_name https://k8s-default-nlbtlsap-5b19f0e967-84960958c6b7c202.elb.us-west-2.amazonaws.com; # this is an example DNS A record for the NLB

      ssl_certificate /etc/nginx/ssl/tls.crt;
      ssl_certificate_key /etc/nginx/ssl/tls.key;

      default_type text/plain;

      location / {
        return 200 "hello from pod $hostname\n";
      }
    }
```

* When the configmap change has been made, check the pod to be sure it is in a running state

```sh
kubectl get pods
```

* Check for the TLS handshake (be sure to use the DNS name of the NLB that is created, not the example DNS name)

```sh
openssl s_client -connect k8s-default-nlbtlsap-5b19f0e967-84960958c6b7c202.elb.us-west-2.amazonaws.com:443

CONNECTED(00000005)
depth=0 CN = www.test-app.pyx-int.com
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 CN = www.test-app.pyx-int.com
verify error:num=21:unable to verify the first certificate
verify return:1
write W BLOCK
---
Certificate chain
 0 s:/CN=www.test-app.pyx-int.com
   i:/CN=www.test-app.pyx-int.com
---
Server certificate
-----BEGIN CERTIFICATE-----
<cert-hash-here>
-----END CERTIFICATE-----
subject=/CN=www.test-app.pyx-int.com
issuer=/CN=www.test-app.pyx-int.com
---
No client certificate CA names sent
Server Temp Key: ECDH, X25519, 253 bits
---
SSL handshake has read 1343 bytes and written 351 bytes
---
New, TLSv1/SSLv3, Cipher is AEAD-CHACHA20-POLY1305-SHA256
Server public key is 2048 bit
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.3
    Cipher    : AEAD-CHACHA20-POLY1305-SHA256
    Session-ID: 
    Session-ID-ctx: 
    Master-Key: 
    Start Time: 1681826163
    Timeout   : 7200 (sec)
    Verify return code: 21 (unable to verify the first certificate)
---
```

* In your browser, go to your NLB domain: `<https://k8s-default-nlbtlsap-5b19f0e967-84960958c6b7c202.elb.us-west-2.amazonaws.com>`
* Check the logs of your pod to see your local machine IP preserved,

```sh
k logs nlb-tls-app-767d8fd94b-95gtn # use the correct pod name
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: /etc/nginx/conf.d/default.conf is not a file or does not exist
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
2023/04/18 13:54:24 [warn] 1#1: the "user" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:2
nginx: [warn] the "user" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:2
/docker-entrypoint.sh: Configuration complete; ready for start up
2023/04/18 13:54:24 [notice] 1#1: using the "epoll" event method
2023/04/18 13:54:24 [notice] 1#1: nginx/1.23.4
2023/04/18 13:54:24 [notice] 1#1: built by gcc 12.2.1 20220924 (Alpine 12.2.1_git20220924-r4) 
2023/04/18 13:54:24 [notice] 1#1: OS: Linux 5.4.238-148.346.amzn2.x86_64
2023/04/18 13:54:24 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2023/04/18 13:54:24 [notice] 1#1: start worker processes
2023/04/18 13:54:24 [notice] 1#1: start worker process 20
2023/04/18 13:54:24 [notice] 1#1: start worker process 21
<your-public-IP> - - [18/Apr/2023:13:59:33 +0000] "GET / HTTP/1.1" 200 44 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/112.0" "-"
<your-public-IP> - - [18/Apr/2023:13:59:33 +0000] "GET /favicon.ico HTTP/1.1" 200 44 "https://k8s-default-nlbtlsap-5b19f0e967-84960958c6b7c202.elb.us-west-2.amazonaws.com/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/112.0" "-"

```

* Clean up

```sh
kubectl delete -f test-app/manifests
```
