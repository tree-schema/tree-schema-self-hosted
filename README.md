# tree-schema-self-hosted

This repo allows you to deploy Tree Schema [Data Catalog](https://treeschema.com) into your own AWS account. 


# Overview

Complete the following steps to deploy Tree Schema:

1. Deploy `templates/template_1_ts_ecs_role.yml`. This will create an ECS execution role that will pull Tree Schema from the AWS ECR repo. The ARN for this role is provided as an output of the template.

2. Provide the ARN for the role created above to Tree Schema. This will grant cross-account access to pull the Tree Schema images. If you don't know who to contact please reach out to [developer@treeschema.com](mailto:developer@treeschema.com).

3. Complete the prerequisites below and update the template parameters in the second template, `templates/template_2_ts_service.yml`

4. Deploy `templates/template_2_ts_service.yml`. This will create the Tree Schema service and configure your database.

5. Validate the deployment and update your DNS records to point to Tree Schema.


See the [Deployment](#deployment) section below for more details.


# Prerequisites

You must have the following before Tree Schema can be launched in your AWS account.

- A VPC that contains the subnets and security groups for the Tree Schema application. As seen in the image below, there should be at least two subnets (one private and one public). While we strongly recommend having three distinct security groups (as defined below), you may deploy Tree Schema with 2, or even 1, security group if you enable the proper networking rules.
  - **Private subnet(s)**: This is where the application will be deployed and where your Postgres and Redis databases should be deployed. Your subnet groups for Postgres and Redis will need to include these subnets.
  - **Public subnet(s)**: This is where the load balancer will be deployed that will route traffic from the internet to the application.
  - **App Security Group**: This is the security group that will be applied to the Tree Schema application. It will need access to the **Database Security Group** for Postgres on port 5432 and Redis on port 6379. If you have other databases in your ecosystem that you want to connect Tree Schema to, this is the security group you will need to provide ingress access to.
  - **Database Security Group**: This is the security group that will be applied to your databases. It needs to allow inbound access to Redis and Postgres from the **App Security Group**. If you use different security groups for Redis and Postgres some minor changes will be required to the template.
  - **Load Balancer Security Group**: This is the security group that will be applied to your load balancer. It needs to allow inbound access on port 80 and 443 to the internet (or a subset of IP addresses where your end users will connect from). It needs ingress access to the **App Security Group** on port 80.

![Required Networking](imgs/required-networking.png?raw=true "Required Networking")

- **A Certificate in ACM**: this is used to provide HTTPS verification on the load balancer deployed with Tree Schema. The Certificate must be in ACM because the Load Balancer requires this certiicate to apply HTTPS. At least two domains are required to deploy Tree Schema, one for the web application and one for the API endpoint. We reccomend creating a certificate that covers at least the two specific sub-domains that you choose, such as `treeschema.your-domain.com` and `api-treeschema.your-domain.com`. If needed, you can further limit access using your security groups to prevent access from the public internet.
  - Note: the sub domain for the API server **must** start with `api-`.
- **A Postgres RDS database**: the database is created separately from the CFT to provide more control over the password and sizing of the database. You will likely be able to start Tree Schema on the smallest database size (micro). Tree Schema supports Postgres 11+ and we reccomend using the newest version of Postgres. Save the user, password, host and initial database name to place into the secrets below.
- **A Redis instance**: the redis instance is created separately from the CFT to provide more control over sizing of the cache. Tree Schema does not need a large cache and it also uses namespaces, therefore reusing an existing Redis instance should not cause any conflicts with your keys.
- **A Secret in AWS Secrets Manager**: the information in this secret is defined below. These are used to pass in secure information to Tree Schema to connect to the databases and optionally provide SSO access via GOogle or Microsoft.
- **An email address verified in SES**: Tree Schema will use to send emails to users. The SES account must also be approved to send emails to non-verified users, this can be done through a [service quota increase](#https://docs.aws.amazon.com/ses/latest/DeveloperGuide/manage-sending-quotas-request-increase.html).
- **A KMS key**: this should be created using symmetric encryption. This key is used by Tree Schema to securely store additional credentials that are required to access your other databases. The image below shows the configurations required, access to this key is granted as part of this CFT to the ECS task role that the Tree Schema application will have.

![KMS Key](imgs/kms-key-configurations.png?raw=true)

## Secret Values

As mentioned above, you will need to create a single AWS Secret. The Tree Schema deployment uses this Secret for both secret values (e.g. username, password, encryption keys) as well as a few configurations (e.g. database hostname, domain name, etc.). 

The following can be used as a shell to create the secrets, the descriptions for each item are defined below. All fields are required unless specified as optional.

```json
{
  "POSTGRES_HOST": "postgres-host.com",
  "POSTGRES_PORT": "5432",
  "POSTGRES_DB": "treeschemadb",
  "POSTGRES_USER": "treeschema",
  "POSTGRES_PASSWORD": "",
  "REDIS_HOST": "redis-host.com",
  "ENCRYPTION_SECRET_KEY": "random-string",
  "DEFAULT_DOMAIN": "https://treeschema.your-domain.com",
  "MICROSOFT_CLIENT_ID": "",
  "MICROSOFT_CLIENT_SECRET": "",
  "GOOGLE_CLIENT_ID": "",
  "GOOGLE_CLIENT_SECRET": ""
}
```

- **POSTGRES_HOST**: The hostname for your Postgres instance
- **POSTGRES_PORT**: The port for your Postgres instance, the default is 5432
- **POSTGRES_DB**: The database used to initialize the Postgres instance, make sure to use the same value that was used when your RDS instance was created. We suggest `treeschemadb`.
- **POSTGRES_USER**: The database user. This user should have read, write, delete, etc. permissions for the database above.
- **POSTGRES_PASSWORD**: The password for the postgres user
- **REDIS_HOST**: The hostname for the Redis instance. Note - Tree Schema does not currently support Redis authentication
- **ENCRYPTION_SECRET_KEY**: A secret that can be used to securely create a one-way hash of sensitive items, this can be generated in Python using the following:

```python
import secrets

length = 50
chars = 'abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)'
secret_key = ''.join(secrets.choice(chars) for i in range(length))
print(secret_key)
```
- **DEFAULT_DOMAIN**: The domain where Tree Schema will be accessible to your organization. This must start with `https://` and should match the domain used in your ACM certificate. This is required for asynchronous processes to have the correct endpoint when sending emaills.
- **MICROSOFT_CLIENT_ID**: (Optional) the client ID required for Microsoft Oauth SSO, leave empty if not used. To create a Microsoft client ID follow the [Microsoft documentation](#https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app). For the redirect URI, use the endpoint `https://<your-treeschema.domain.com>/login/microsoft/login/callback/`
- **MICROSOFT_CLIENT_SECRET**: (Optional) the client secret required for Microsoft Oauth SSO, leave empty if not used
- **GOOGLE_CLIENT_ID**: (Optional) the client ID required for Google Oauth SSO, leave empty if not used. To create a Google client ID follow the [Google documentation](#https://developers.google.com/identity/sign-in/web/sign-in). For the redirect URI, use the endpoint `https://<your-treeschema.domain.com>/login/google/login/callback/`
- **GOOGLE_CLIENT_SECRET**: (Optional) the client secret required for Google Oauth SSO, leave empty if not used

## Template Parameters

The following describes the parameters in the `template_1_ts_ecs_role.yml` file:

- **EnvStageName**: The environment name, this allows you to deploy the Tree Schema ECS role more than once in the same account / region if desired. You can use any value for this, we suggest are prod, dev and stage.

The following describes the parameters in the `template_2_ts_service.yml` file:

- **EnvStageName**: The environment name, this allows you to deploy Tree Schema more than once in the same account / region if desired. You can use any value for this, we suggest are prod, dev and stage.
- **VpcId**: The ID of the VPC that the stack will be deployed into. This should be in the format `vpc-...`
- **AppSecurityGroups**: The Security Group ID(s) that the Tree Schema app will be deployed into. If more than one are provided use a comma seperated list with no spaces. This should be in the format `sg-...,sg-...`
- **LoadBalancerSecurityGroups**: The Security Group ID(s) that the Load Balancer for Tree Schema will be deployed into. If more than one are provided use a comma seperated list with no spaces. This should be in the format **sg-...,sg-...**
- **AppSubnets**: The Subnets that the Tree Schema Application will be deployed into. If more than one are provided use a comma seperated list with no spaces. This should be in the format `subnet-...,subnet-...`
- **LoadBalancerSubnets**: The Subnets that the Tree Schema Load Balancer will be deployed into. If more than one are provided use a comma seperated list with no spaces. This should be in the format `subnet-...,subnet-...`
- **LoadBalancerCertArn**: The ARN for the certificate in ACM that covers the two sub domains where you will access Tree Schema (e.g. `api-treeschema.your-host.com` and `treeschema.your-host.com`).
- **SecretsArn**: The ARN of the secrets defined above.
- **FromEmailAddress**: The email address used as the **from** email when Tree Schema sends emails. Tree Schema uses AWS SES to send emails.
- **KmsKeyArn**: The ARN of the KMS key created above
- **TreeSchemaImage**: The Image for the Tree Schema application container. The image will be provided by Tree Schema.
- **TreeSchemaNginxImage**: The Image for the Tree Schema Nginx container. The image will be provided by Tree Schema.
- **TreeSchemaApiImage**: The Image for the Tree Schema API container. The image will be provided by Tree Schema.

# Deployment

Two examples are provided for how to deploy Tree Schema, one via the CLI, which requires the [aws-sam-cli](https://pypi.org/project/aws-sam-cli/) to be installed. And a second example, via the CloudFormation GUI.

### Deploy with SAM

1. Fill in the script parameters in the `scripts/deploy_1.sh` file.

2. Run the deploy script with 
```bash
sh scripts/deploy_1.sh
```

You can optionally pass in a profile with an argument:
```bash
sh scripts/deploy_1.sh my_profile
```

Otherwise the **default** profile will be used. You can find the ARN for the role in the output:

![Tree Schema ECS Role SAM](imgs/sam-deploy-ecs-arn.png?raw=true)

3. Fill in the template parameters for `scripts/deploy_2.sh`.

4. Run the second deployment script, you can also optionally pass in your profile.

```bash 
sh scripts/deploy_2.sh
```

### Deploy with CloudFormation GUI

1. Upload the first template `templates/template_1_ts_ecs_role.yml` to CloudFormation and create the role. The ARN for the role created will be available in the CloudFormation outputs:

![Tree Schema ECS Role CloudFormation](imgs/cf-deploy-ecs-arn.png?raw=true)

2. After providing the role ARN to Tree Schema, upload the second template, `templates/template_2_ts_service.yml` and configure the parameters:

![Tree Schema ECS Service CloudFormation](imgs/cf-deploy-tree-schema.png?raw=true)


# Post Deployment

After the CloudFormation deployment is completed we can validate that the application is working by navigating to the DNS name created for the load balancer. This can be retrieved as part of the second stack's output or from the load balancer details page (Ec2 > Load Balancers) and selecting the Tree Schema load balancer. The website will show as unsecure since it is not being accessed from a domain name covered in the certificate.

![Tree Schema access not private](imgs/tree-schema-access-not-private.png?raw=true)

Selecting proceed should bring up the Tree Schema application. Once this is confirmed to be working the two sub-domains need to be registered with the DNS in order to route traffic to your Tree Schema application using the human friendly name. Add two CNAME records to your DNS that both point to the DNS name of your Load Balancer, as seen here:

![DNS Records](imgs/tree-schema-dns-records.png?raw=true)

Your Tree Schema deployment is now complete.


# Architecture Overview

This section describes the resources that will be deployed.

![Tree Schema Resources](imgs/tree-schema-self-host-resources.png?raw=true)


## Resources Created

### Roles

- **TreeSchemaECSExecutionRole**: This is created from the first template. It creates a role that the AWS ECS service will assume. This role orchestrates the deployment of containers into ECS. This role also needs to be provided to Tree Schema in order to provide permission to pull the containers from ECS.
- **TreeSchemaECSTaskRole**: This is the role that the ECS Containers running Tree Schema will assume. The access is limited to reading the pre-defined KMS key, listing CloudWatch logs and writing to the Tree Schema CloudWatch group, reading and writing to the S3 bucket that is created as well as sending emails as the verified SES email address provided.

### ECS 

- **TreeSchemaECSCluster**: The cluster that ECS services are deployed into. Tree Schema deploys all containers as Fargate services and the cluster itself is a logical container that does not accrue a cost.
- **TreeSchemaLogGroup**: A log group to save all logs to. Logs are purged after 30 days. The Tree Schema 
app containers only have access to write to this log group.
- **TreeSchemaCeleryLogGroup**: A log group to save all logs to for the async processor. Logs are purged after 30 days. The Tree Schema async container only has access to write to this log group.
- **TreeSchemaTaskDefinition**: The task that runs three containers, including an Nginx container, the Tree 
Schema App container and the Tree Schema API container.
- **TreeSchemaCeleryTaskDefinition**: The task that runs three containers, including an Nginx container, the Tree Schema App container and the Tree Schema API container.
- **TreeSchemaService**: A long-running ervice to keep the TreeSchemaTaskDefinition running at all times.
- **TreeSchemaCeleryService**: A long-running ervice to keep the TreeSchemaCeleryTaskDefinition running at all times.
- **TreeSchemaLoadBalancer**: The load balancer that allows inbound traffic to access the Tree Schema app deployed within ECS.
- **TreeSchemaHttpsListener**: A load balancer rule that routes HTTPS traffic into the Tree Schema App
- **TreeSchemaHttpListener**: A load balancer rule that routes HTTP traffic to the HTTPS listener to enforce HTTPS across all connections.
- **TreeSchemaTargetGroup**: A target group to connect the load balancer to the ECS service and to ensure that containers are healthy.



# Debugging Errors

Start by reviewing the CloudFormation output in the console or your terminal. If there are any errors deploying AWS resources you will be notified here.


Most errors in the Tree Schema deployments come from network configurations that do not have the required access. These errors may only show in the application logs and they might only come up after the CloudFormation deployment has been completed. Tree Schema creates logs in CloudWatch that can be used to help debug these errors. All logs are saved to the log group `/aws/ecs/tree-schema` and are further broken down by the specific resource (e.g. app server, API server, celery worker, etc.). You can quickly access these logs directly from ECS by navigating to the Tree Schema cluster that was created and the specific task that is failing.

For additional help, please contac [developer@treeschema.com](mailto:developer@treeschema.com).

# Using the API

You can can configure your Python client to point to your own Tree Schema deployment. See `examples.api.py` for details.

