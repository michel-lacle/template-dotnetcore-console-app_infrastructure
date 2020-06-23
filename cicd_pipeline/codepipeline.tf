resource "aws_s3_bucket" "build_cache" {
  # make sure bucket name is DNS compliant
  bucket = replace("codepipeline_${var.application_name}_${var.branch}", "_", "-" )
  acl = "private"

  tags = {
    Application = var.application_name
  }
}

resource "aws_iam_role" "codepipeline" {
  name = "codepipeline-${var.application_name}-${var.branch}"

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

  tags = {
    Application = var.application_name
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "codepipeline-${var.application_name}-${var.branch}"
  role = aws_iam_role.codepipeline.id

  policy = file("${path.module}/codepipeline_iam_policy.json")
}

resource "aws_codepipeline" "this" {
  name = "${var.application_name}-${var.branch}"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.build_cache.bucket
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name = "Source"
      category = "Source"
      owner = "AWS"
      provider = "CodeCommit"
      version = "1"
      output_artifacts = [
        "SourceArtifact"]

      configuration = {
        RepositoryName = var.repository_name
        BranchName = var.branch
        PollForSourceChanges = true
      }

      namespace = "SourceVariables"
    }
  }

  stage {
    name = "Build"

    action {
      name = "Build"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      input_artifacts = [
        "SourceArtifact"]
      output_artifacts = [
        "BuildArtifact"]
      version = "1"

      configuration = {
        ProjectName = aws_codebuild_project.this.name
      }

      namespace = "BuildVariables"
    }
  }

  stage {
    name = "Deploy"

    action {
      name = "Deploy"
      category = "Deploy"
      owner = "AWS"
      provider = "CodeDeploy"
      input_artifacts = [
        "BuildArtifact"]
      version = "1"

      configuration = {
        ApplicationName = aws_codedeploy_app.this.name
        DeploymentGroupName = aws_codedeploy_deployment_group.this.deployment_group_name
      }
    }
  }

  tags = {
    Application = var.application_name
  }
}