resource "aws_codebuild_project" "terraform_plan" {
  name          = "${var.name}-tf-plan"
  description   = "terraform codebuild plan project"
  build_timeout = var.cb_plan_timeout
  service_role  = aws_iam_role.codebuild_terraform.arn

  environment {
    compute_type                = var.cb_env_compute_type
    image                       = var.cb_env_image
    type                        = var.cb_env_type
    image_pull_credentials_type = var.cb_env_image_pull_credentials_type

    environment_variable {
      name  = "TERRAFORM_VERSION"
      value = var.cb_tf_version
    }
    environment_variable {
      name  = "TF_CLI_ARGS"
      value = "-no-color -input=false"
    }
  }
  artifacts {
    type                = "CODEPIPELINE"
    artifact_identifier = "plan_output"
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = <<BUILDSPEC
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.x
    commands:
      - wget -q https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - unzip ./terraform_$${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/
      - rm terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
  pre_build:
    commands:
      - terraform init -backend-config=./init-tfvars/${var.cb_env_name}.tfvars
  build:
    commands:
      - echo Build started on `date`
      - terraform plan -out=tfplan -var-file=./apply-tfvars/${var.cb_env_name}.tfvars
  post_build:
    commands:
      - echo Entered the post_build phase...
      - echo Build completed on `date`
artifacts:
  name: plan_output
  files:
    - '**/*'
BUILDSPEC
  }

  #- tfplan
  tags = merge(
    var.input_tags,
    {
      "Name" = "${var.name}-tf-plan"
    },
  )
}

resource "aws_codebuild_project" "terraform_apply" {
  name          = "${var.name}-tf-apply"
  description   = "terraform codebuild apply project"
  build_timeout = var.cb_apply_timeout
  service_role  = aws_iam_role.codebuild_terraform.arn

  environment {
    compute_type                = var.cb_env_compute_type
    image                       = var.cb_env_image
    type                        = var.cb_env_type
    image_pull_credentials_type = var.cb_env_image_pull_credentials_type

    environment_variable {
      name  = "TERRAFORM_VERSION"
      value = var.cb_tf_version
    }
    environment_variable {
      name  = "TF_CLI_ARGS"
      value = "-no-color -input=false"
    }
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = <<BUILDSPEC
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.x
    commands:
      - wget -q https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - unzip ./terraform_$${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/
      - rm terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
  pre_build:
    commands:
      - terraform init -backend-config=./init-tfvars/${var.cb_env_name}.tfvars
  build:
    commands:
      - echo Build started on `date`
      - terraform apply -input=false tfplan
  post_build:
    commands:
      - echo Entered the post_build phase...
      - echo Build completed on `date`
BUILDSPEC
  }
  #- cp $CODEBUILD_SRC_DIR_plan_output/tfplan .

  tags = merge(
    var.input_tags,
    {
      "Name" = "${var.name}-tf-apply"
    },
  )
}

