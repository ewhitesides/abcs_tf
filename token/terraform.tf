terraform {

  required_version = ">= 1.4.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.58.0"
    }
  }

  #abcs-tf bucket should exist already
  #aws s3api create-bucket
  #--bucket abcs-tf \
  #--region us-east-2 \
  #--create-bucket-configuration LocationConstraint=us-east-2

  backend "s3" {
    bucket = "abcs-tf"
    key    = "token_refresh/terraform.tfstate"
    region = "us-east-2"
  }
}
