
# CloudWatch Event Rule for CodeCommit
resource "aws_cloudwatch_event_rule" "codecommit_rule" {
  name        = "codecommit-update-rule"
  description = "Triggers on CodeCommit repository update"

  event_pattern = jsonencode({
    source     = ["aws.codecommit"],
    detail-type = ["CodeCommit Repository State Change"],
    resources   = ["${module.codecommit_infrastructure_source_repo.arn}"],
    detail      = {
      event      = ["referenceCreated", "referenceUpdated"],
      referenceType = ["branch"],
      referenceName = ["main"]  # Replace with your branch name if different
    }
  })
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "pipeline_target" {
  rule      = aws_cloudwatch_event_rule.codecommit_rule.name
  arn       = module.codepipeline_terraform.arn
  role_arn  = aws_iam_role.event_role.arn
}

# IAM Role for EventBridge to trigger CodePipeline
resource "aws_iam_role" "event_role" {
  name = "EventBridgeCodePipelineRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })
}

# IAM Policy to allow the role to start CodePipeline
resource "aws_iam_role_policy" "event_policy" {
  name   = "EventBridgeCodePipelinePolicy"
  role   = aws_iam_role.event_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action   = "codepipeline:StartPipelineExecution",
      Effect   = "Allow",
      Resource = "${module.codepipeline_terraform.arn}"
    }]
  })
}

