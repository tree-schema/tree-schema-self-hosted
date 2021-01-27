#!/bin/bash

# Script parameters
STACK_NAME=tree-schema
ENV_STAGE_NAME=prod
VPC_ID='vpc-08f519d04ca17fd96'
APP_SECURITY_GROUPS='sg-0696c0e5240ce9252'
LOAD_BALANCER_SECURITY_GROUPS='sg-0a1d73dbb9e153d05'
APP_SUBNETS='subnet-0a36c9c4b8f0752f3,subnet-0c51af3048d90ba16'
LOAD_BALANCER_SUBNETS='subnet-05286657db5291d4c,subnet-050d577e527203da4'
LOAD_BALANCER_CERT_ARN='arn:aws:acm:us-east-1:656100572794:certificate/c5303b3a-d3c8-44e3-a204-497811be6073'
SECRETS_ARN='arn:aws:secretsmanager:us-east-1:656100572794:secret:tree-schema-secret-poI9VH'
FROM_EMAIL_ADDRESS='asher@treeschema.com'
KMS_KEY_ARN='arn:aws:kms:us-east-1:656100572794:key/7e1d9f18-bae3-4068-ac51-96b4e4cdd6bf'
TREE_SCHEMA_IMAGE='215001001805.dkr.ecr.us-east-1.amazonaws.com/tree-schema-data-catalog-app:0.0.1'
TREE_SCHEMA_NGINX_IMAGE='215001001805.dkr.ecr.us-east-1.amazonaws.com/tree-schema-data-catalog-nginx:0.0.1'
TREE_SCHEMA_API_IMAGE='215001001805.dkr.ecr.us-east-1.amazonaws.com/tree-schema-data-catalog-api:0.0.1'

# Allow overriding profile
if [ "$1" ]; then
    PROFILE=$1
  else
    PROFILE='default'
fi

sam deploy \
--template-file templates/template_2_ts_service.yml \
--stack-name $STACK_NAME \
--capabilities CAPABILITY_NAMED_IAM \
--profile $PROFILE \
--parameter-overrides "\
  ParameterKey=EnvStageName,ParameterValue=$ENV_STAGE_NAME \
  ParameterKey=VpcId,ParameterValue=$VPC_ID \
  ParameterKey=AppSecurityGroups,ParameterValue=$APP_SECURITY_GROUPS \
  ParameterKey=LoadBalancerSecurityGroups,ParameterValue=$LOAD_BALANCER_SECURITY_GROUPS \
  ParameterKey=AppSubnets,ParameterValue=$APP_SUBNETS \
  ParameterKey=LoadBalancerSubnets,ParameterValue=$LOAD_BALANCER_SUBNETS \
  ParameterKey=LoadBalancerCertArn,ParameterValue=$LOAD_BALANCER_CERT_ARN \
  ParameterKey=SecretsArn,ParameterValue=$SECRETS_ARN \
  ParameterKey=FromEmailAddress,ParameterValue=$FROM_EMAIL_ADDRESS \
  ParameterKey=KmsKeyArn,ParameterValue=$KMS_KEY_ARN \
  ParameterKey=TreeSchemaImage,ParameterValue=$TREE_SCHEMA_IMAGE \
  ParameterKey=TreeSchemaNginxImage,ParameterValue=$TREE_SCHEMA_NGINX_IMAGE \
  ParameterKey=TreeSchemaApiImage,ParameterValue=$TREE_SCHEMA_API_IMAGE \
"
