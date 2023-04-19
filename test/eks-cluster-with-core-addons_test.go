package src

import (

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"strings"
	"testing"
	"time"
	"context"
	"encoding/base64"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/eks"
	apps "k8s.io/api/apps/v1"
	core "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"log"
	"sigs.k8s.io/aws-iam-authenticator/pkg/token"
)

var (
	//Test Driven tests Inputs https://github.com/golang/go/wiki/TableDrivenTests
	testCases = []struct {
		name        string
		region      string
		eks_cluster string
		values      map[string]string
	}{
		{
			"terratest-eks-cluster-with-core-addons",
			"us-west-2",
			"terratest-eks-cluster-with-core-addons",
			map[string]string{
				"rootFolder":        "../",
				"exampleFolderPath": "examples/eks-cluster-with-core-addons"},
		},
	}

	// apply the infrastructure in a specific order
	// this prevents errors that stem from EKS resources
	// that are dependent on VPC resources
	applyModules = []string{
		"full_apply", //apply everything else that's not in a module (like standalone resources)
	}

	// Destroy everything in the reverse order it was applied
	// with a full cleanup at the end to grab any remaining resources still needing
	// to be destroyed
	destroyModules = []string{
		"module.addons",
		"module.eks_cluster",
		"module.vpc",
		"full_destroy", //destroy everything else that was not destroyed by the modules.
	}

	/*Update the expected Output variables and values*/
	outputParameters = [...]Outputs{
	{"eks_cluster_id", "terratest-eks-cluster-with-core-addons", "equal"},
	{"region", "us-west-2", "equal"},
	{"vpc_private_subnet_cidr", "[10.0.10.0/24 10.0.11.0/24]", "equal"},
	{"vpc_public_subnet_cidr", "[10.0.0.0/24 10.0.1.0/24]", "equal"},
	}

		/*EKS API Validation*/
	expectedEKSWorkerNodes = 3

	/*Update the expected Deployments names and the namespace*/
	expectedDeployments = [...]Deployment{
		{"aws-load-balancer-controller", "kube-system"},
		{"cluster-proportional-autoscaler-coredns", "kube-system"},
		{"coredns", "kube-system"},
		{"argo-cd-argocd-applicationset-controller", "argocd"},
		{"argo-cd-argocd-dex-server", "argocd"},
		{"argo-cd-argocd-notifications-controller", "argocd"},
		{"argo-cd-argocd-repo-server", "argocd"},
		{"argo-cd-argocd-server", "argocd"},
		{"argo-cd-redis-ha-haproxy", "argocd"},
	}

	/*Update the expected DaemonSet names and the namespace*/
	expectedDaemonSets = [...]DaemonSet{
		{"aws-node", "kube-system"},
		{"kube-proxy", "kube-system"},
		{"aws-cloudwatch-metrics", "amazon-cloudwatch"},
		{"csi-secrets-store-provider-aws", "csi-secrets-store-provider-aws"},
		{"secrets-store-csi-driver", "secrets-store-csi-driver"},
	}

	/*Update the expected K8s Services names and the namespace*/
	expectedServices = [...]Services{
		{"argo-cd-argocd-application-controller", "argocd", "ClusterIP"},
		{"argo-cd-argocd-applicationset-controller", "argocd", "ClusterIP"},
		{"argo-cd-argocd-dex-server", "argocd", "ClusterIP"},
		{"argo-cd-argocd-repo-server", "argocd", "ClusterIP"},
		{"argo-cd-argocd-server", "argocd", "LoadBalancer"},
		{"kubernetes", "default", "ClusterIP"},
		{"aws-load-balancer-webhook-service", "kube-system", "ClusterIP"},
		{"kube-dns", "kube-system", "ClusterIP"},
	}
)

type Outputs struct {
	OutputVariable      string
	ExpectedOutputValue string
	AssertType          string
}

type Deployment struct {
	Name      string
	Namespace string
}

type DaemonSet struct {
	Name      string
	Namespace string
}

type Services struct {
	Name      string
	Namespace string
	Type      core.ServiceType
}

func getTerraformOptions(t *testing.T, inputTfOptions *terraform.Options) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, inputTfOptions)
}


func TestEksWithCoreAddons(t *testing.T) {
		t.Parallel()

		for _, testCase := range testCases {
			testCase := testCase
			t.Run(testCase.name, func(subT *testing.T) {
				subT.Parallel()
				tempExampleFolder := test_structure.CopyTerraformFolderToTemp(t, testCase.values["rootFolder"], testCase.values["exampleFolderPath"])

				inputTfOptions := &terraform.Options{
					NoColor:      true,
					TerraformDir: tempExampleFolder,
					VarFiles: []string{"fixtures.us-west-2.tfvars"},
					
					//Vars is left here as an example of how to pass vars without using a tfvars file, similar to how you would by using the -var terraform CLI argument
					// Vars: map[string]interface{}{
					// 	"cluster_name:" "terratest-eks"
					// 	"contact": "cae-team@caylent.com"
					// 	"environment": "sbx"
					// 	"team": "caylent-team"
					// 	"purpose": "terratest"
					// },
				}

				terratestOptions := getTerraformOptions(t, inputTfOptions)

				//* At the end of the test, run `terraform destroy` to clean up any resources that were created */
				defer test_structure.RunTestStage(t, "destroy", func() {
					for _, target := range destroyModules {
						if target != "full_destroy" {
							destroyTFOptions := &terraform.Options{
								/*The path to where our Terraform code is located*/
								TerraformDir: tempExampleFolder,
								VarFiles: []string{"fixtures.us-west-2.tfvars"}, // The var file paths to pass to Terraform commands using -var-file option.
								//Vars is left here as an example of how to pass vars without using a tfvars file, similar to how you would by using the -var terraform CLI argument
								// Vars: map[string]interface{}{
								// 	"cluster_name:" "terratest-eks"
								// 	"contact": "cae-team@caylent.com"
								// 	"environment": "sbx"
								// 	"team": "caylent-team"
								// 	"purpose": "terratest"
								// },
								//BackendConfig: map[string]interface{}{
								//	"bucket": S3BackendConfig["bucketName"],
								//	"key":    S3BackendConfig["s3Prefix"]+testCase.name,
								//	"region": S3BackendConfig["awsRegion"],
								//},
								Targets: []string{target},
								NoColor: true,
							}
							terraformOptions := getTerraformOptions(t, destroyTFOptions)
							terraform.Destroy(t, terraformOptions)
							time.Sleep(2 * time.Minute) // Workaround for cleaning up dangling ENIs
						} else {
							terraformOptions := getTerraformOptions(t, inputTfOptions)
							terraform.Destroy(t, terraformOptions)
						}
					}
				})

				// Run Init and Apply
				// Apply in phases so that VPC resources are created before EKS resources
				test_structure.RunTestStage(t, "apply", func() {
					for _, target := range applyModules {
						if target != "full_apply" {
							applyTfOptions := &terraform.Options{
								/*The path to where our Terraform code is located*/
								TerraformDir: tempExampleFolder,
								VarFiles: []string{"fixtures.us-west-2.tfvars"}, // The var file paths to pass to Terraform commands using -var-file option.
								//Vars is left here as an example of how to pass vars without using a tfvars file, similar to how you would by using the -var terraform CLI argument
								// Vars: map[string]interface{}{
								// 	"cluster_name:" "terratest-eks"
								// 	"contact": "cae-team@caylent.com"
								// 	"environment": "sbx"
								// 	"team": "caylent-team"
								// 	"purpose": "terratest"
								// },
								Targets: []string{target},
								NoColor: true,
							}
							test_structure.SaveTerraformOptions(t, tempExampleFolder, terratestOptions)
							terraformOptions := getTerraformOptions(t, applyTfOptions)
							terraform.InitAndApplyE(t, terraformOptions)
							time.Sleep(2 * time.Minute) // wait 2 min between iteration so resources have time to propogate
						} else {
							terraformOptions := getTerraformOptions(t, inputTfOptions)
							terraform.InitAndApplyE(t, terraformOptions)
						}
					}
				},
			)

				t.Run("TF_PLAN_VALIDATION", func(t *testing.T) {
				// Run Plan diff
				test_structure.RunTestStage(t, "plan", func() {
					terraformOptions := test_structure.LoadTerraformOptions(t, tempExampleFolder)
					planResult := terraform.Plan(t, terraformOptions)

					// Make sure the plan shows zero changes
					assert.Contains(t, planResult, "No changes.")
					})
				})

				t.Run("TF_OUTPUTS_VALIDATION", func(t *testing.T) {
					/*Outputs Validation*/
					test_structure.RunTestStage(t, "outputs_validation", func() {
						terraformOptions := test_structure.LoadTerraformOptions(t, tempExampleFolder)
						for _, tc := range outputParameters {
							t.Run(tc.OutputVariable, func(t *testing.T) {
								ActualOutputValue := terraform.Output(t, terraformOptions, tc.OutputVariable)
								switch strings.ToLower(tc.AssertType) {
								case "equal":
									assert.Equal(t, tc.ExpectedOutputValue, ActualOutputValue)
								case "notempty":
									assert.NotEmpty(t, ActualOutputValue)
								case "contains":
									assert.Contains(t, ActualOutputValue, tc.ExpectedOutputValue)
								}
							})
						}
					})
				})

				t.Run("EKS_ADDON_VALIDATION", func(t *testing.T) {
				/*EKS and Addon Validation*/
				test_structure.RunTestStage(t, "eks_addon_validation", func() {
					terraformOptions := test_structure.LoadTerraformOptions(t, tempExampleFolder)
					eksClusterName := terraform.Output(t, terraformOptions, "eks_cluster_id")
					awsRegion := terraform.Output(t, terraformOptions, "region")
					eksAddonValidation(t, eksClusterName, awsRegion)
				})
			})
			})
		}
}

func eksAddonValidation(t *testing.T, eksClusterName string, awsRegion string) {
	/****************************************************************************/
	/*EKS Cluster Result
	/****************************************************************************/
	result, err := EksDescribeCluster(awsRegion, eksClusterName)
	if err != nil {
		t.Errorf("Error describing EKS Cluster: %v", err)
	}
	/****************************************************************************/
	/*K8s ClientSet
	/****************************************************************************/
	k8sclient, err := GetKubernetesClient(result.Cluster)
	if err != nil {
		t.Errorf("Error creating Kubernees clientset: %v", err)
	}

	/****************************************************************************/
	/*TEST: Match Cluster Name
	/****************************************************************************/
	t.Run("MATCH_EKS_CLUSTER_NAME", func(t *testing.T) {
		assert.Equal(t, eksClusterName, aws.StringValue(result.Cluster.Name))
	})

	/****************************************************************************/
	/*TEST: Verify the total number of nodes running
	/****************************************************************************/
	nodes, err := k8sclient.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		t.Errorf("Error getting EKS nodes: %v", err)
	}
	t.Run("MATCH_TOTAL_EKS_WORKER_NODES", func(t *testing.T) {
		assert.Equal(t, expectedEKSWorkerNodes, len(nodes.Items))
	})

	/****************************************************************************/
	/*Test: Validate Kubernetes Deployments
	/****************************************************************************/
	t.Run("EKS_DEPLOYMENTS_VALIDATION", func(t *testing.T) {
		for _, dep := range expectedDeployments {
			deployment, err := GetDeployment(k8sclient, dep.Name, dep.Namespace)
			if err != nil {
				assert.Fail(t, "DEPLOYMENT: %s | NAMESPACE: %s | Error: %s", dep.Name, dep.Namespace, err)
			} else {
				t.Log("|-----------------------------------------------------------------------------------------------------------------------|")
				t.Logf("DEPLOYMENT: %s | NAMESPACE: %s | READY: %d | AVAILABLE: %d | REPLICAS: %d | UNAVAILABLE: %d",
					dep.Name, dep.Namespace,
					deployment.Status.ReadyReplicas,
					deployment.Status.AvailableReplicas,
					deployment.Status.Replicas,
					deployment.Status.UnavailableReplicas)
				t.Logf("|-----------------------------------------------------------------------------------------------------------------------|")
				t.Run("MATCH_REPLICAS_VS_READY-REPLICAS/"+dep.Name, func(t *testing.T) {
					assert.Equal(t, aws.Int32Value(deployment.Spec.Replicas), deployment.Status.ReadyReplicas)
				})
				t.Run("UNAVAILABLE_REPLICAS/"+dep.Name, func(t *testing.T) {
					assert.Equal(t, int32(0), deployment.Status.UnavailableReplicas)
				})
			}
		}
	})

	/****************************************************************************/
	/*Test: Validate Kubernetes DaemonSets
	/****************************************************************************/
	t.Run("EKS_DAEMONSETS_VALIDATION", func(t *testing.T) {
		for _, daemon := range expectedDaemonSets {
			daemonset, err := GetDaemonSet(k8sclient, daemon.Name, daemon.Namespace)
			if err != nil {
				assert.Fail(t, "DaemonSet: %s | NAMESPACE: %s| Error: %s", daemon.Name, daemon.Namespace, err)
			} else {
				t.Log("|-----------------------------------------------------------------------------------------------------------------------|")
				t.Logf("DaemonSet: %s | NAMESPACE: %s | DESIRED: %d | CURRENT: %d | READY: %d  AVAILABLE: %d | UNAVAILABLE: %d",
					daemon.Name,
					daemon.Namespace,
					daemonset.Status.DesiredNumberScheduled,
					daemonset.Status.CurrentNumberScheduled,
					daemonset.Status.NumberReady,
					daemonset.Status.NumberAvailable,
					daemonset.Status.NumberUnavailable)
				t.Logf("|-----------------------------------------------------------------------------------------------------------------------|")
				t.Run("MATCH_DESIRED_VS_CURRENT_PODS/"+daemon.Name, func(t *testing.T) {
					assert.Equal(t, daemonset.Status.DesiredNumberScheduled, daemonset.Status.CurrentNumberScheduled)
				})
				t.Run("UNAVAILABLE_REPLICAS/"+daemon.Name, func(t *testing.T) {
					assert.Equal(t, int32(0), daemonset.Status.NumberUnavailable)
				})

			}
		}
	})

	/****************************************************************************/
	/*Test: Validate Kubernetes Services
	/****************************************************************************/
	t.Run("EKS_SERVICES_VALIDATION", func(t *testing.T) {
		for _, service := range expectedServices {
			services, err := GetServices(k8sclient, service.Name, service.Namespace)
			if err != nil {
				assert.Fail(t, "SERVICE NAME: %s | NAMESPACE: %s| Error: %s", service.Name, service.Namespace, err)
			} else {
				t.Log("|-----------------------------------------------------------------------------------------------------------------------|")
				t.Logf("SERVICE NAME: %s | NAMESPACE: %s | STATUS: %s",
					service.Name,
					service.Namespace,
					services.Spec.Type)
				t.Logf("|-----------------------------------------------------------------------------------------------------------------------|")
				t.Run("SERVICE_STATUS/"+service.Name, func(t *testing.T) {
					assert.Equal(t, services.Spec.Type, service.Type)
				})
			}
		}
	})

}


// Helpers

func ListDeploymentItems(k8sclient *kubernetes.Clientset, namespace string) (*apps.DeploymentList, error) {
	deployments, err := k8sclient.AppsV1().Deployments(namespace).List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		log.Fatalf("Error listing the deployments: %v", err)
		return nil, err
	}

	return deployments, nil
}

func GetDeployment(k8sclient *kubernetes.Clientset, deploymentName string, namespace string) (*apps.Deployment, error) {
	deployment, err := k8sclient.AppsV1().Deployments(namespace).Get(context.TODO(), deploymentName, metav1.GetOptions{})
	if err != nil {
		log.Printf("Error getting the deployment: %v", err)
		return nil, err
	}
	return deployment, nil
}

func GetDaemonSet(k8sclient *kubernetes.Clientset, DaemonSetName string, namespace string) (*apps.DaemonSet, error) {
	DaemonSet, err := k8sclient.AppsV1().DaemonSets(namespace).Get(context.TODO(), DaemonSetName, metav1.GetOptions{})
	if err != nil {
		log.Printf("Error getting the DaemonSet: %v", err)
		return nil, err
	}
	return DaemonSet, nil
}

func GetServices(k8sclient *kubernetes.Clientset, ServiceName string, namespace string) (*core.Service, error) {
	service, err := k8sclient.CoreV1().Services(namespace).Get(context.TODO(), ServiceName, metav1.GetOptions{})
	if err != nil {
		log.Printf("Error getting the Services: %v", err)
		return nil, err
	}
	return service, nil
}

func EksDescribeCluster(region string, clusterName string) (*eks.DescribeClusterOutput, error) {
	svc := NewEksSession(region)
	input := &eks.DescribeClusterInput{
		Name: aws.String(clusterName),
	}

	result, err := svc.DescribeCluster(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case eks.ErrCodeResourceNotFoundException:
				fmt.Println(eks.ErrCodeResourceNotFoundException, aerr.Error())
			case eks.ErrCodeClientException:
				fmt.Println(eks.ErrCodeClientException, aerr.Error())
			case eks.ErrCodeServerException:
				fmt.Println(eks.ErrCodeServerException, aerr.Error())
			case eks.ErrCodeServiceUnavailableException:
				fmt.Println(eks.ErrCodeServiceUnavailableException, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			fmt.Println(err.Error())
		}
	}
	return result, err
}

func NewEksSession(region string) *eks.EKS {
	mySession := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(region),
	}))
	svc := eks.New(mySession)
	return svc
}

func GetKubernetesClient(cluster *eks.Cluster) (*kubernetes.Clientset, error) {
	log.Printf("%+v", cluster)
	gen, err := token.NewGenerator(true, false)
	if err != nil {
		return nil, err
	}
	opts := &token.GetTokenOptions{
		ClusterID: aws.StringValue(cluster.Name),
	}
	tok, err := gen.GetWithOptions(opts)
	if err != nil {
		return nil, err
	}
	ca, err := base64.StdEncoding.DecodeString(aws.StringValue(cluster.CertificateAuthority.Data))
	if err != nil {
		return nil, err
	}
	k8sclient, err := kubernetes.NewForConfig(
		&rest.Config{
			Host:        aws.StringValue(cluster.Endpoint),
			BearerToken: tok.Token,
			TLSClientConfig: rest.TLSClientConfig{
				CAData: ca,
			},
		},
	)
	if err != nil {
		return nil, err
	}
	return k8sclient, nil
}
