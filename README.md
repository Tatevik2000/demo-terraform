# Amazon ECS Demo with fullstack app / DevOps practices / Terraform sample

## Table of content

   * [Solution overview](#solution-overview)
   * [General information](#general-information)
   * [Infrastructure](#infrastructure)
      * [Infrastructure Architecture](#infrastructure-architecture)
        * [Infrastructure considerations due to demo proposals](#infrastructure-considerations-due-to-demo-proposals)
      * [Prerequisites](#prerequisites)
      * [Usage](#usage)
      * [Autoscaling test](#autoscaling-test)
   * [Application Code](#application-code)
     * [Client app](#client-app)
       * [Client considerations due to demo proposal](#client-considerations-due-to-demo-proposals)
     * [Server app](#server-app)
   * [Cleanup](#cleanup)
   * [Security](#security)
   * [License](#license)
   

## Solution overview

This repository contains Terraform code to deploy a solution that is intended to be used to run a demo. It shows how AWS resources can be used to build an architecture that reduces defects while deploying, eases remediation, mitigates deployment risks and improves the flow into production environments while gaining the advantages of a managed underlying infrastructure for containers.

## General information

The project has been divided into two parts: 
- Code: the code for the running application
    - client: Vue.js code for the frontend application
    - server: Node.js code for the backend application
- Infrastructure: contains the Terraform code to deploy the needed AWS resources for the solution

## Infrastructure

The Infrastructure folder contains the terraform code to deploy the AWS resources. The *Modules* folder has been created to store the Terraform modules used in this project. The *Templates* folder contains the different configuration files needed within the modules. The Terraform state is stored locally in the machine where you execute the terraform commands, but feel free to set a Terraform backend configuration like an AWS S3 Bucket or Terraform Cloud to store the state remotely. The AWS resources created by the script are detailed bellow:

- AWS Networking resources, following best practices for HA
- 2 ECR Repositories
- 1 ECS Cluster
- 2 ECS Services
- 2 Task definitions
- 4 Autoscaling Policies + Cloudwatch Alarms
- 2 Application Load Balancer (Public facing)
- IAM Roles and policies for ECS Tasks
- Security Groups for ALBs and ECS tasks
- 1 DynamoDB table (used by the application)


## Application Code

### Client app

The Client folder contains the code to run the frontend. This code is written in Vue.js and uses the port 80 in the deployed version, but when run localy it uses port 3000.

The application folder structure is separeted in components, views and services, despite the router and the assets.

### Client considerations due to demo proposals
1) The assets used by the client application are going to be requested from the S3 bucket created with this code. Please add 3 images to the created S3 bucket.

2) The DynamoDB structure used by the client application is the following one:

```shell
  - id: N (HASH)
  - path: S
  - title: S
```
Feel free to change the structure as needed. But in order to have full demo experience, please add 3 DynamoDB Items with the specified structure from above. Below is an example.

*Note: The path attribute correspondes to the S3 Object URL of each added asset from the previous step.*

Example of a DynamoDB Item:

```json
{
  "id": {
    "N": "1"
  },
  "path": {
    "S": "https://mybucket.s3.eu-central-1.amazonaws.com/MyImage.jpeg"
  },
  "title": {
    "S": "My title"
  }
}
```

### Server app

The Server folder contains the code to run the backend. This code is written in Node.js and uses the port 80 in the deployed version, but when run localy it uses port 3001.

Swagger was also implemented in order to document the APIs. The Swagger endpoint is provided as part of the Terraform output, you can grab the output link and access it through a browser.

The server exposes 3 endpoints:
- /status: serves as a dummy endpoint to know if the server is up and running. This one is used as the health check endpoint by the AWS ECS resources
- /api/getAllProducts: main endpoint, which returns all the Items from an AWS DynamoDB table
- /api/docs: the Swagger endpoint for the API documentation

## Cleanup

Run the following command if you want to delete all the resources created before:

```shell
terraform destroy -var aws_profile="your-profile" -var AWS_REGION="your-region" -var environment_name="your-env" -var github_token="your-personal-token" -var repository_name="your-github-repository" - var repository_owner="the-github-repository-owner"
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License
This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.
