resource "aws_dynamodb_table" "gigs" {
  name         = "Gigs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }
}