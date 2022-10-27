<!-- BEGIN_TF_DOCS -->
# terraform-aws-codepipeline-iac

GitHub: [StratusGrid/terraform-aws-codepipeline-iac](https://github.com/StratusGrid/terraform-aws-codepipeline-iac)

This repository lets you create a codepipeline and supporting codebuilds etc. for automatically deploying terraform code.

<span style="color:red">NOTE:</span> Due to a bug in Terraform, we must ignore_changes on the github configuration to prevent it from attempting to update oauthtoken on every apply. If this ever needs to be updated, the existing pipeline will be destroyed and recreated; OR the following code block can simply be removed from the codepipeline-terraform.tf file.
```
lifecycle {
ignore_changes = [stage[0].action[0].configuration]
}
```

## Example
```hcl
module "cloudfront_codepipeline" {
  source                = "github.com/StratusGrid/terraform-aws-codepipeline-iac"
  name                  = "${var.name_prefix}-unique-name${local.name_suffix}"
  cp_tf_manual_approval = [true] # leave array empty to not have a manual approval step
  codebuild_iam_policy  = local.cloudfront_codebuild_policy
  cb_env_compute_type   = "BUILD_GENERAL1_SMALL"
  cb_env_image          = "aws/codebuild/standard:2.0"
  cb_env_type           = "LINUX_CONTAINER"
  cb_tf_version         = "0.12.24"
  cb_env_name           = var.env_name
  cp_source_oauth_token = "Call this token via secret manager ideally"
  cp_source_owner       = "my-org"
  cp_source_repo        = "my-repo"
  cp_source_branch      = var.env_name

  cb_env_image_pull_credentials_type = "CODEBUILD"
  cp_source_poll_for_changes         = true
}

locals {
  cloudfront_codebuild_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::${var.backend_name}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::${var.backend_name}/funicom-delivery-static-${var.env_name}.tfstate"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/${var.backend_name}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:GenerateDataKey"
            ],
            "Resource": "${var.tf_kms_key_id}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "${module.cloudfront_codepipeline.codepipeline_resources_bucket_arn}",
                "${module.cloudfront_codepipeline.codepipeline_resources_bucket_arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Describe*",
                "kms:Get*",
                "kms:List*",
                "iam:*",
                "codepipeline:*",
                "codebuild:*",
                "codedeploy:*",
                "cloudfront:*",
                "s3:*",
                "lambda:*",
                "apigateway:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
POLICY
}
```
---

## Requirements

No requirements.

## Resources

| Name | Type |
|------|------|
| [aws_codebuild_project.terraform_apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codebuild_project.terraform_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codepipeline.codepipeline_terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_iam_role.codebuild_terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codepipeline_role_terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.codebuild_policy_terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codepipeline_policy_terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.pipeline_resources_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.pipeline_resources_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.pipeline_resources_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.pipeline_resources_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cb_apply_timeout"></a> [cb\_apply\_timeout](#input\_cb\_apply\_timeout) | Maximum time in minutes to wait while applying terraform before killing the build | `number` | `60` | no |
| <a name="input_cb_env_compute_type"></a> [cb\_env\_compute\_type](#input\_cb\_env\_compute\_type) | Valid Values: BUILD\_GENERAL1\_SMALL \| BUILD\_GENERAL1\_MEDIUM \| BUILD\_GENERAL1\_LARGE \| BUILD\_GENERAL1\_2XLARGE | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| <a name="input_cb_env_image"></a> [cb\_env\_image](#input\_cb\_env\_image) | The image tag or image digest that identifies the Docker image to use for this build project. | `string` | `"aws/codebuild/standard:2.0"` | no |
| <a name="input_cb_env_image_pull_credentials_type"></a> [cb\_env\_image\_pull\_credentials\_type](#input\_cb\_env\_image\_pull\_credentials\_type) | The type of credentials AWS CodeBuild uses to pull images in your build. There are two valid values | `string` | `"CODEBUILD"` | no |
| <a name="input_cb_env_name"></a> [cb\_env\_name](#input\_cb\_env\_name) | should pull from env\_name of calling terraform. | `string` | n/a | yes |
| <a name="input_cb_env_type"></a> [cb\_env\_type](#input\_cb\_env\_type) | Valid Values: WINDOWS\_CONTAINER \| LINUX\_CONTAINER \| LINUX\_GPU\_CONTAINER \| ARM\_CONTAINER | `string` | `"LINUX_CONTAINER"` | no |
| <a name="input_cb_plan_timeout"></a> [cb\_plan\_timeout](#input\_cb\_plan\_timeout) | Maximum time in minutes to wait while generating terraform plan before killing the build | `number` | `15` | no |
| <a name="input_cb_tf_version"></a> [cb\_tf\_version](#input\_cb\_tf\_version) | Version of terraform to download and install. Must match version scheme used for URL creation on terraform site. | `string` | n/a | yes |
| <a name="input_codebuild_iam_policy"></a> [codebuild\_iam\_policy](#input\_codebuild\_iam\_policy) | JSON string defining codebuild IAM policy (must be passed in from caller). | `string` | n/a | yes |
| <a name="input_cp_source_branch"></a> [cp\_source\_branch](#input\_cp\_source\_branch) | repository branch. for our purposes, this is often the same as the name of the environment (dev/qa/prd). | `string` | n/a | yes |
| <a name="input_cp_source_oauth_token"></a> [cp\_source\_oauth\_token](#input\_cp\_source\_oauth\_token) | GitHub OAuth token which grants access to source repository. | `string` | n/a | yes |
| <a name="input_cp_source_owner"></a> [cp\_source\_owner](#input\_cp\_source\_owner) | GitHub user account name | `string` | n/a | yes |
| <a name="input_cp_source_poll_for_changes"></a> [cp\_source\_poll\_for\_changes](#input\_cp\_source\_poll\_for\_changes) | true/false should codepipeline poll for source code changes. | `bool` | n/a | yes |
| <a name="input_cp_source_repo"></a> [cp\_source\_repo](#input\_cp\_source\_repo) | name of repository to clone | `string` | n/a | yes |
| <a name="input_cp_tf_manual_approval"></a> [cp\_tf\_manual\_approval](#input\_cp\_tf\_manual\_approval) | determines if terraform pipeline requires manual approval for application. | `list(any)` | `[]` | no |
| <a name="input_input_tags"></a> [input\_tags](#input\_input\_tags) | Map of tags to apply to resources | `map(string)` | <pre>{<br>  "Developer": "StratusGrid",<br>  "Provisioner": "Terraform"<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | name to prepend to all resource names within module | `string` | `"codepipline-module"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codepipeline_resources_bucket_arn"></a> [codepipeline\_resources\_bucket\_arn](#output\_codepipeline\_resources\_bucket\_arn) | outputs the full arn of the bucket created |

---

<span style="color:red">Note:</span> Manual changes to the README will be overwritten when the documentation is updated. To update the documentation, run `terraform-docs -c .config/.terraform-docs.yml .`
<!-- END_TF_DOCS -->