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
    name = "Plan"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["plan_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.terraform_plan.name
      }
    }
  }

  dynamic stage {
    for_each = var.cp_tf_manual_approval

    content {
      name = "Approve"
  
      action {
        name      = "Approval"
        category  = "Approval"
        owner     = "AWS"
        provider  = "Manual"
        version   = "1"
  
        configuration = {
          CustomData         = "Please review the codebuild output and verify the changes."
          ExternalEntityLink = " "
        }
      }
    }
  }

  stage {
    name = "Apply"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      #input_artifacts = ["source_output", "plan_output"]
      input_artifacts = ["plan_output"]
      version         = "1"

      configuration = {
        ProjectName   = aws_codebuild_project.terraform_apply.name,
        #PrimarySource = "source_output"
        PrimarySource = "plan_output"
      }
    }
  }
}
