# Overview

terraform code to deploy aws resources for the abcs project

## token

the token folder contains the code related to rotating the google oauth2 token in aws

## Prerequisites

the s3 bucket must be created manually before running the terraform code.

```bash
aws s3api create-bucket --bucket abcs-tf --region us-east-2 --create-bucket-configuration LocationConstraint=us-east-2

#output
#{
#    "Location": "http://abcs-tf.s3.amazonaws.com/"
#}
```