resource "aws_codepipeline" "codepipeline_terraform" {
  #lifecycle {
  #  ignore_changes = [stage[0].action[0].configuration]
  #}

  name     = "${var.name}-cp-terraform"
  role_arn = aws_iam_role.codepipeline_role_terraform.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_resources_bucket.bucket
    type     = "S3"
  }
  tags = merge(
    var.input_tags,
    {
      "Name" = "${var.name}-cp-terraform"
    },
  )
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]


      configuration = {
        Owner                 = var.cp_source_owner
        Repo                  = var.cp_source_repo
        Branch                = var.cp_source_branch
        OAuthToken            = var.cp_source_oauth_token
        PollForSourceChanges  = var.cp_source_poll_for_changes
      }
    }
  }
  stage {
    name = "Plan-and-Apply"

    action {
      name             = "Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["plan_output"]
      version          = "1"
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.terraform_plan.name
      }
    }

    dynamic "action" {
      for_each = var.cp_tf_manual_approval
      content {
        name             = "Approval"
        category         = "Approval"
        owner            = "AWS"
        provider         = "Manual"
        configuration    = {
          CustomData         = "Please review the codebuild output and verify the changes."
          ExternalEntityLink = " "
        }
        input_artifacts  = []
        output_artifacts = []
        version          = "1"
        run_order        = 2
      }
    }

    action {
      name             = "Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      #input_artifacts = ["source_output", "plan_output"]
      input_artifacts  = ["plan_output"]
      version          = "1"
      run_order        = 3

      configuration = {
        ProjectName   = aws_codebuild_project.terraform_apply.name,
        PrimarySource = "plan_output"
      }
    }
  }
}
