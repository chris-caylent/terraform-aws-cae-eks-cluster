package test

// This Terratest file is here to serve as an example of a test structure
// You may use bits and pieces of this to suit your needs

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"strings"
	"testing"
	"time"
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
			"eks-core",
			"us-west-2",
			"terratest-eks-core",
			map[string]string{
				"rootFolder":        "../",
				"exampleFolderPath": "examples/eks-core"},
		},
	}

	// apply the infrastructure in a specific order
	// this prevents errors that stem from EKS resources
	// that are dependent on VPC resources
	applyModules = []string{
		"module.vpc",
		"module.eks_core",
		"full_apply", //apply everything else that's not in a module (like the KMS alias)
	}

	destroyModules = []string{
		"module.eks_core",
		"module.vpc",
		"full_destroy", //destroy everything else that was not destroyed by the modules.
	}

	/*Update the expected Output variables and values*/
	 outputParameters = [...]Outputs{
	 	{"eks_cluster_id", "terratest-eks", "equal"},
	 }

)

type Outputs struct {
	OutputVariable      string
	ExpectedOutputValue string
	AssertType          string
}

func getTerraformOptions(t *testing.T, inputTfOptions *terraform.Options) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, inputTfOptions)
}


func TestEksCore(t *testing.T) {
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
					// 	"contact": "cae-team@caylent.com.com"
					// 	"environment": "sbx"
					// 	"team": "caylent"
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
								// 	"contact": "cae-team@caylent.com.com"
								// 	"environment": "sbx"
								// 	"team": "caylent"
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
				// Apply in phases so that VPC resources are created before EKS resources are
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
								// 	"contact": "cae-team@caylent.com.com"
								// 	"environment": "sbx"
								// 	"team": "caylent"
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
			})
		}
}