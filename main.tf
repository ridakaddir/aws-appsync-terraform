resource "aws_appsync_graphql_api" "my_appsync" {
  authentication_type = "API_KEY"
  name = "my_appsync"
  schema = file("./schema.graphql")
  xray_enabled = true
}

resource "aws_appsync_api_key" "appsync_api_key" {
  api_id = aws_appsync_graphql_api.my_appsync.id

}

resource "aws_dynamodb_table" "campaigns_table" {
  name = "campaigns"
  hash_key = "campaignId"
  
  read_capacity = 1
  write_capacity = 1
  
  attribute {
    name = "campaignId"
    type = "S"
  }

}

resource "aws_iam_role" "appsync_role" {
  name = "appsync_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "campaign_table_full_access_role_policy" {
  name = "campaign_table_full_access_role_policy"
  role = aws_iam_role.appsync_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_dynamodb_table.campaigns_table.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_appsync_datasource" "campaigns_table_datasource" {
  api_id = aws_appsync_graphql_api.my_appsync.id
  name = "appsync_campaigns_datasource"
  service_role_arn = aws_iam_role.appsync_role.arn
  type = "AMAZON_DYNAMODB"
  dynamodb_config {
    table_name = aws_dynamodb_table.campaigns_table.name
  }
}

resource "aws_appsync_resolver" "single_campaign_resolver" {
  api_id = aws_appsync_graphql_api.my_appsync.id
  field = "singleCampaign"
  type = "Query"
  data_source = aws_appsync_datasource.campaigns_table_datasource.name
  request_template = file("./resolvers/Query.singleCampaign.req.vtl")
  response_template = file("./resolvers/Query.singleCampaign.res.vtl")
}

resource "aws_appsync_resolver" "create_campaign_resolver" {
  api_id = aws_appsync_graphql_api.my_appsync.id
  field = "createCampaign"
  type = "Mutation"
  data_source = aws_appsync_datasource.campaigns_table_datasource.name
  request_template = file("./resolvers/Mutation.createCampaign.req.vtl")
  response_template = file("./resolvers/Mutation.createCampaign.res.vtl")
}


output "api_key" {
  value = aws_appsync_api_key.appsync_api_key.key
  sensitive = true
}
