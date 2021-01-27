#!/bin/bash

# Script parameters
STACK_NAME=tree-schema-ecs-role
ENV_STAGE_NAME=prod

# Allow overriding profile
if [ "$1" ]; then
    PROFILE=$1
  else
    PROFILE='default'
fi

sam deploy \
--template-file templates/template_1_ts_ecs_role.yml \
--stack-name $STACK_NAME \
--capabilities CAPABILITY_NAMED_IAM \
--profile $PROFILE \
--parameter-overrides "ParameterKey=EnvStageName,ParameterValue=$ENV_STAGE_NAME"
