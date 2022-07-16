resource "aws_api_gateway_rest_api" "api" {
  name = var.api_name
}

resource "aws_api_gateway_deployment" "dev" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      // src directory
      data.archive_file.src_zip.output_base64sha256,
      // Endpoint definitions
      module.endpoint_ping.sha1_output,

    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.dev.id
  stage_name    = "dev"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_log.arn
    format = ""
  }
}

resource "aws_cloudwatch_log_group" "api_gw_access_log" {
  name = "/aws/api_gateway/enrollment-api/dev"
}

resource "aws_cloudwatch_log_group" "api_gw_execution_log" {
  name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/${aws_api_gateway_stage.dev.stage_name}"
}

data "aws_iam_policy_document" "enrollment_api_logger_role_policy_doc" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "enrollment_api_logger_role_policy_cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role" "enrollment_api_logger" {
  name               = "enrollment-api-logger"
  assume_role_policy = data.aws_iam_policy_document.enrollment_api_logger_role_policy_doc.json
}

resource "aws_iam_role_policy" "enrollment_api_logger_policy_1" {
  role   = aws_iam_role.enrollment_api_logger.id
  policy = data.aws_iam_policy_document.enrollment_api_logger_role_policy_cloudwatch.json
}

resource "aws_api_gateway_account" "enrollment_api" {
  cloudwatch_role_arn = aws_iam_role.enrollment_api_logger.arn
}

resource "aws_s3_bucket" "src" {
  bucket_prefix = "eb-src-"
}

resource "aws_s3_bucket_acl" "src" {
  bucket = aws_s3_bucket.src.id
  acl    = "private"
}

data "archive_file" "src_zip" {
  type = "zip"

  source_dir  = "${path.module}/src"
  output_path = "${path.module}/src.zip"
}

resource "aws_s3_object" "src_zip" {
  bucket = aws_s3_bucket.src.id

  key    = "src.zip"
  source = data.archive_file.src_zip.output_path

  etag = filemd5(data.archive_file.src_zip.output_path)
}

resource "aws_api_gateway_authorizer" "main" {
  name        = "main"
  type        = "COGNITO_USER_POOLS"
  rest_api_id = aws_api_gateway_rest_api.api.id
  provider_arns = [
    var.user_pool_arn
  ]
}


module "tables" {
  source = "./data"
}

///////////////////////////////////////////////////////////////////////////////
// Endpoints

module "endpoint_ping" {
  source  = "app.terraform.io/abcballpark/rest-api-endpoint/aws"
  version = "0.1.8"
  endpoint_name      = "ping"
  api_name           = aws_api_gateway_rest_api.api.name
  api_id             = aws_api_gateway_rest_api.api.id
  src_bucket         = aws_s3_bucket.src.id
  src_key            = aws_s3_object.src_zip.key
  handler            = "index.ping"
  http_method        = "GET"
  src_hash           = data.archive_file.src_zip.output_base64sha256
  parent_resource_id = aws_api_gateway_rest_api.api.root_resource_id
  authorizer_id      = aws_api_gateway_authorizer.main.id
}
