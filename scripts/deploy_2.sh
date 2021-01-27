#!/bin/bash

# Script parameters
STACK_NAME=tree-schema
ENV_STAGE_NAME=prod
VPC_ID=''
APP_SECURITY_GROUPS=''
LOAD_BALANCER_SECURITY_GROUPS=''
APP_SUBNETS=''
LOAD_BALANCER_SUBNETS=''
LOAD_BALANCER_CERT_ARN=''
SECRETS_ARN=''
FROM_EMAIL_ADDRESS=''
KMS_KEY_ARN=''
TREE_SCHEMA_IMAGE='656100572794.dkr.ecr.us-east-1.amazonaws.com/tree-schema-data-catalog-app:0.0.1'
TREE_SCHEMA_NGINX_IMAGE='656100572794.dkr.ecr.us-east-1.amazonaws.com/tree-schema-data-catalog-nginx:0.0.1'
TREE_SCHEMA_API_IMAGE='656100572794.dkr.ecr.us-east-1.amazonaws.com/tree-schema-data-catalog-api:0.0.1'

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
