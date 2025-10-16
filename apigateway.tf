resource "aws_apigatewayv2_api" "gig_diary_api" {
  name          = "GigDiaryAPI"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.gig_diary_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.gig_diary_function.invoke_arn
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.gig_diary_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.gig_diary_api.id
  name        = "$default"
  auto_deploy = true
}