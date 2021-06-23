// Provider Info
provider "aws" {
  region              = var.region
}

resource "aws_sns_topic" "scp-sns" {
  display_name      = "Org-SCP-Change-Detected"
  name              = "SCP-Change-Monitoring"
  tags              = {}
}

resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.scp-sns.arn
  policy = data.aws_iam_policy_document.scp_sns_topic_policy.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "scp_sns_topic_policy" {
  policy_id = "scp_sns_policy"
  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_sns_topic.scp-sns.arn,
    ]
  }

  statement {
    actions = ["SNS:Publish"]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [
      aws_sns_topic.scp-sns.arn,
    ]
    sid = "AWSEvents_scp-monitoring"
  }
}

resource "aws_sns_topic_subscription" "scp_sns_topic_subscription" {
  topic_arn = aws_sns_topic.scp-sns.arn
  protocol  = "email"
  endpoint  = var.notify_target_email
}

resource "aws_cloudwatch_event_rule" "monitor-CloudTrail-SCP" {
    description    = "scp-monitoring"
    event_bus_name = "default"
    event_pattern  = jsonencode(
        {
            detail      = {
                eventName   = [
                    "UpdatePolicy",
                    "CreatePolicy",
                    "DeletePolicy",
                    "DetachPolicy",
                    "DisablePolicyType",
                    "EnablePolicyType",
                    "AttachPolicy"
                ]
                eventSource = [
                    "organizations.amazonaws.com",
                ]
            }
            detail-type = [
                "AWS API Call via CloudTrail",
            ]
            source      = [
                "aws.organizations",
            ]
        }
    )
    is_enabled     = true
    name           = "scp-monitoring"
    tags           = {}
}

# aws_cloudwatch_event_target.scp-target:
resource "aws_cloudwatch_event_target" "scp-notify" {
    arn            = aws_sns_topic.scp-sns.arn
    rule           = aws_cloudwatch_event_rule.monitor-CloudTrail-SCP.name
    target_id      = "scp-notify"
    input_transformer {
        input_paths    = {
            "event"     = "$.detail.eventName"
            "event-id"  = "$.detail.eventID"
            "principal" = "$.detail.userIdentity.arn"
            "time"      = "$.detail.eventTime"
        }
        input_template = "\"The following <event> event for SCP was performed by <principal> at <time>. For more information please query CloudTrail with event ID: <event-id> or the accompanying secondary event payload email\""
    }
}

# aws_cloudwatch_event_target.scp-target2:
resource "aws_cloudwatch_event_target" "scp-target-payload" {
    arn            = aws_sns_topic.scp-sns.arn
    rule           = aws_cloudwatch_event_rule.monitor-CloudTrail-SCP.name
    target_id      = "scp-detailed-payload"
}
