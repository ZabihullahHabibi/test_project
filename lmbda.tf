#  create iam role for lambda 
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [ # this statment allow lambad access aws 
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Sid    = "",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
      {   # this statment allow lambad to access scheduler 
      "Effect": "Allow", 
      "Principal": {
        "Service": "scheduler.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }

    ],
  })
}

#  making .zip file of lambda python code and store in terraform file
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../src/lambda.py"
  output_path = "lambda_function_payload.zip"
}

#  creatting lambda function and uploading .zip file 
resource "aws_lambda_function" "lambda_function" {
  filename         = "lambda_function_payload.zip"
  function_name    = "lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
  depends_on = [ aws_sns_topic.email_notification ] # this part is depend on sns and should run after sns created

  environment {
    variables = {
        TOPIC_ARN = aws_sns_topic.email_notification.arn # get sns topic arn and assing to env variable TOPIC_ARN

    }
  }
}

#  add permission to lambda function to call sns
resource "aws_lambda_permission" "sns_publish" {
    function_name = aws_lambda_function.lambda_function.function_name
    statement_id  = "AllowSNSPublish"
    action        = "lambda:PublishMessage"
    principal     = "sns.amazonaws.com"
    source_arn    = aws_sns_topic.email_notification.arn
}

#  add permission to lambda function to be called by aws cloud watch event rule
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_5_minutes.arn
}
