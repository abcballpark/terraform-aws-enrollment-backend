resource "aws_api_gateway_rest_api" "api" {
  name = var.api_name
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

  key    = "api-src.zip"
  source = data.archive_file.src_zip.output_path

  etag = filemd5(data.archive_file.src_zip.output_path)
}

module "endpoint_ping" {
  source  = "app.terraform.io/abcballpark/rest-api-endpoint/aws"
  version = "0.1.4"

  endpoint_name      = "ping"
  api_name           = aws_api_gateway_rest_api.api.name
  api_id             = aws_api_gateway_rest_api.api.id
  src_bucket         = aws_s3_bucket.src.id
  src_key            = aws_s3_object.src_zip.key
  handler            = "index.ping"
  http_method        = "GET"
  src_hash           = data.archive_file.src_zip.output_base64sha256
  parent_resource_id = aws_api_gateway_rest_api.api.root_resource_id
}
