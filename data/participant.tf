resource "aws_dynamodb_table" "participant" {
  name           = "Participant"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "ParticipantId"
  range_key      = "UserId"

  attribute {
    name = "ParticipantId"
    type = "S"
  }

  attribute {
    name = "UserId"
    type = "S"
  }
}
