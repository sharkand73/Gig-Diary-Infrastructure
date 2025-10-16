variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "lambda_path" {
  description = "Path to lambda function"
  type        = string
  default     = "lambda/GigDiary.zip"
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.api.invoke_url
}

output "react_app_bucket_name" {
  value = aws_s3_bucket.react_app.bucket
}

output "react_app_website_url" {
  value = aws_s3_bucket_website_configuration.react_app.website_endpoint
}