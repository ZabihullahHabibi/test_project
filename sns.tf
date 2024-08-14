# create an email address for sending notification to
locals {
  emails = ["zabihullah4830@gmail.com"]
}

#  create aws sns topic
resource "aws_sns_topic" "email_notification" {
    name            = "email_notification"
    delivery_policy = jsonencode({
        "http" : {
        "defaultHealthyRetryPolicy" : {
            "minDelayTarget" : 20,
            "maxDelayTarget" : 20,
            "numRetries" : 3,
            "numMaxDelayRetries" : 0,
            "numNoDelayRetries" : 0,
            "numMinDelayRetries" : 0,
            "backoffFunction" : "linear"
        },
        "disableSubscriptionOverrides" : false,
        "defaultThrottlePolicy" : {
            "maxReceivesPerSecond" : 1
        }
        }
    })
}

#  create sns topic subscription of an email to send notification to 
resource "aws_sns_topic_subscription" "topic_email_subscription" {
  count     = length(local.emails)
  topic_arn = aws_sns_topic.email_notification.arn
  protocol  = "email"
  endpoint  = local.emails[count.index]
}


#  Attaches a policy to the SNS topic, allowing various SNS actions such as subscribing, publishing, and modifying topic attributes.
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.email_notification.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json

}
# Defines the policy document that specifies the permissions for the SNS topic. It allows our lambda to perform SNS actions on the topic.
data "aws_iam_policy_document" "sns_topic_policy" {
    policy_id = "__default_policy_ID"

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

        effect = "Allow"

        principals {
        type        = "AWS"
        identifiers = [aws_iam_role.lambda_role.arn]
        }

        resources = [
        aws_sns_topic.email_notification.arn
        ]
        sid = "__default_statement_ID"
    }
}