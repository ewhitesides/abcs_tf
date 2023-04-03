#secret path for storing the google oauth2 credential file contents
#the credentials at this path can be used to generate a new token
#would require manually running the code on local machine because it uses web ui to approve connecting to google account
#terraform import aws_secretsmanager_secret.prod_abcs_ggloauthcred arn:aws:secretsmanager:us-east-2:227821232291:secret:prod/abcs/ggloauthcred-QG11WV
resource "aws_secretsmanager_secret" "prod_abcs_ggloauthcred" {
  name        = "prod/abcs/ggloauthcred"
  description = "copy of the google oauth2 credential file"
}

#secret path for storing the google oauth2 token
#this path is used by the main application
resource "aws_secretsmanager_secret" "prod_abcs_ggloauthtoken" {
  name = "prod/abcs/ggloauthtoken"
  #commenting out the below because it creates a cyclic dependency
  #(lambda function needs the secret to exist, but the secret needs the lambda function to exist)
  #rotation_enabled    = true
  #rotation_lambda_arn = aws_lambda_function.abcs_token.arn
  #rotation_rules {
  #  automatically_after_days = 1
  #}
}

#create ecr repo for token image
#terraform state show aws_ecr_repository.abcs_token
resource "aws_ecr_repository" "abcs_token" {
  name = "abcs_token"
  image_scanning_configuration {
    scan_on_push = true
  }
}

#todo create credential for github actions to push to ecr
# resource "aws_iam_user" "abcs_ecr_push" {
# name = "abcs_ecr_push"
# path = "/abcs/"
# }

#assume role policy
#aws iam list-roles
#terraform import aws_iam_role.abcs_token_role abcs_token-role-h918evqe
data "aws_iam_policy_document" "abcs_token_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
  version = "2012-10-17"
}

#managed policy
#aws iam list-policies
#terraform import aws_iam_policy.abcs_token_AWSLambdaBasicExecutionRole arn:aws:iam::227821232291:policy/service-role/AWSLambdaBasicExecutionRole-9a9a3e22-36c7-4718-bdef-c38dd6ed7b64
data "aws_iam_policy_document" "abcs_token_AWSLambdaBasicExecutionRolePolicyDoc" {
  statement {
    actions   = ["logs:CreateLogGroup"]
    effect    = "Allow"
    resources = ["arn:aws:logs:us-east-2:227821232291:*"]
  }
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    effect    = "Allow"
    resources = ["arn:aws:logs:us-east-2:227821232291:log-group:/aws/lambda/abcs_token:*"]
  }
  statement {
    actions = ["secretsmanager:GetSecretValue"]
    effect  = "Allow"
    resources = [
      aws_secretsmanager_secret.prod_abcs_ggloauthcred.arn
    ]
  }
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage"
    ]
    effect = "Allow"
    resources = [
      aws_secretsmanager_secret.prod_abcs_ggloauthtoken.arn
    ]
  }
  version = "2012-10-17"
}
resource "aws_iam_policy" "abcs_token_AWSLambdaBasicExecutionRole" {
  name     = "AWSLambdaBasicExecutionRole-9a9a3e22-36c7-4718-bdef-c38dd6ed7b64"
  path     = "/service-role/"
  policy   = data.aws_iam_policy_document.abcs_token_AWSLambdaBasicExecutionRolePolicyDoc.json
  tags     = {}
  tags_all = {}
}

#iam role
resource "aws_iam_role" "abcs_token_role" {
  assume_role_policy    = data.aws_iam_policy_document.abcs_token_assume_role.json
  force_detach_policies = false
  managed_policy_arns = [
    aws_iam_policy.abcs_token_AWSLambdaBasicExecutionRole.arn
  ]
  max_session_duration = 3600
  name                 = "abcs_token-role-h918evqe"
  path                 = "/service-role/"
  tags                 = {}
  tags_all             = {}
}

#lambda function
#terraform import aws_lambda_function.abcs_token arn:aws:lambda:us-east-2:227821232291:function:abcs_token
resource "aws_lambda_function" "abcs_token" {
  architectures                  = ["x86_64"]
  function_name                  = "arn:aws:lambda:us-east-2:227821232291:function:abcs_token"
  image_uri                      = "227821232291.dkr.ecr.us-east-2.amazonaws.com/abcs_token:latest"
  layers                         = []
  memory_size                    = 128
  package_type                   = "Image"
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.abcs_token_role.arn
  skip_destroy                   = false
  tags                           = {}
  tags_all                       = {}
  timeout                        = 30

  ephemeral_storage {
    size = 512
  }

  tracing_config {
    mode = "PassThrough"
  }

  environment {
    variables = {
      AWS_SECRET_PATH_GOOGLE_CRED  = aws_secretsmanager_secret.prod_abcs_ggloauthcred.name
      AWS_SECRET_PATH_GOOGLE_TOKEN = aws_secretsmanager_secret.prod_abcs_ggloauthtoken.name
    }
  }
}

#allow secretsmanager source arn to invoke the lambda function
resource "aws_lambda_permission" "allow_lambda_invoke" {
  statement_id  = "AllowInvokeFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.abcs_token.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.prod_abcs_ggloauthtoken.arn
}
