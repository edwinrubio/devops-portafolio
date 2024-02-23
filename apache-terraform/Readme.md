# Application Deployment with Terraform

The goal of this project is to write Terraform Infrastructure as Code (IaC) to deploy an Apache web server in the AWS cloud.

## Pre-Requisites

- Create the following resources using Terraform IaC:
  - Create an S3 Bucket to store Terraform state files.
  - Create DynamoDB.
  - Deploy a VPC network using Terraform IaC and keep the state file in an S3 backend.

- Create the following resources using Terraform IaC and keep the state file in an S3 backend:
  - S3 Bucket to store web server configuration and the `user-data.sh` script file which will configure the web server.
  - SNS topic for notifications.
  - IAM Role.
  - Golden AMI.

## Deployment

Write Terraform IaC to deploy the following resources in the VPC created in the Pre-Requisites step and keep the state file in an S3 backend with state locking support.

- Create an IAM Role granting PUT/GET access to the S3 Bucket and Session Manager access.
- Create a Launch Configuration with a user data script to pull the `use-data.sh` file from S3 and attach IAM role (the `user-data.sh` file will configure the web server).
- Create an Auto Scaling Group with Min:1 Max: 1 Des: 1 in a private subnet.
- Create a Target Group with health checks and attach it to the Auto Scaling Group.
- Create an Application Load Balancer in a public subnet and configure the Listener Port to route traffic to the Target Group.
- Create an alias record in the Hosted Zone to route traffic to the Load Balancer from the public network.
- Create CloudWatch Alarms to send notifications when the ASG state changes.
- Create Scaling Policies to scale out/Scale In when average CPU utilization is > 80%.

Deploy Terraform IaC to create the resources.

[Source of challenge](https://devopsrealtime.com/deploy-apache-web-server-using-terraform-iac/)
