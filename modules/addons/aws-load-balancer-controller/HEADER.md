# aws-load-balancer-controller

# Introduction

AWS Load Balancer Controller is a controller to help manage Elastic Load Balancers for a Kubernetes cluster.

- It satisfies Kubernetes Ingress resources by provisioning Application Load Balancers.
- It satisfies Kubernetes Service resources by provisioning Network Load Balancers.

# Helm Chart

### Instructions to use Helm Charts

Add Helm repo for AWS managed LB Ingress Controller

    helm repo add aws-load-balancer-controller https://aws.github.io/eks-charts

    https://github.com/aws/eks-charts/blob/master/stable/aws-load-balancer-controller/values.yaml

    https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller