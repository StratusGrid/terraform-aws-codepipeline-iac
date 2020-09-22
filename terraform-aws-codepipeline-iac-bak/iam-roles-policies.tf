### CODEBUILD TERRAFORM IAM ROLE ###
resource "aws_iam_role" "codebuild_terraform" {
  name = "${var.name}-build"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = var.input_tags
}

resource "aws_iam_role_policy" "codebuild_policy_terraform" {
  name   = "${var.name}-build"
  role   = aws_iam_role.codebuild_terraform.id
  policy = var.codebuild_iam_policy
}



### CODEPIPELINE TERRAFORM IAM ROLE ###
resource "aws_iam_role" "codepipeline_role_terraform" {
  name = "${var.name}-codepipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy_terraform" {
  name = "${var.name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role_terraform.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.pipeline_resources_bucket.arn}",
        "${aws_s3_bucket.pipeline_resources_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplication",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
      ],
        "Resource": "*",
        "Effect": "Allow"
    }
  ]
}
EOF
}
