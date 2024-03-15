# Amazon ECS Demo with fullstack app / DevOps practices / Terraform sample

## Table of content

   * [Solution overview](#solution-overview)
   * [General information](#general-information)
   * [Infrastructure](#infrastructure)
      * [Infrastructure Architecture](#infrastructure-architecture)
        * [Infrastructure considerations due to demo proposals](#infrastructure-considerations-due-to-demo-proposals)
      * [CI/CD Architecture](#ci/cd-architecture)
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
- 1 SNS topic for notifications

## Infrastructure Architecture

The following diagram represents the Infrastructure architecture being deployed with this project:

<p align="center">
  <img src="Documentation_assets/Infrastructure_architecture.png"/>
</p>

 
**5.** Review the terraform plan, take a look at the changes that terraform will execute:

```shell
terraform apply -var aws_profile="your-profile" -var aws_region="your-region" -var environment_name="your-env" -var github_token="your-personal-token" -var repository_name="your-github-repository" -var repository_owner="the-github-repository-owner"
```

**6.** Once Terraform finishes the deployment, open the AWS Management Console and go to the AWS CodePipeline service. You will see that the pipeline, which was created by this Terraform code, is in progress. Add some files and DynamoDB items as mentioned [here](#client-considerations-due-to-demo-proposals). Once the pipeline finished successfully and the before assets were added, go back to the console where Terraform was executed, copy the *application_url* value from the output and open it in a browser.

**7.** In order to access the also implemented Swagger endpoint, copy the *swagger_endpoint* value from the Terraform output and open it in a browser.

## Autoscaling test

To test how your application will perform under a peak of traffic, a stress test configuration file is provided.

For this stress test [Artillery](https://artillery.io/) is being used. Please be sure to install it following [these](https://artillery.io/docs/guides/getting-started/installing-artillery.html) steps.

Once installed, please change the ALB DNS to the desired layer to test (front/backend) in the **target** attribute, which you can copy from the generated Terraform output, or you can also search it in the AWS Management Console.

To execute it, run the following commands:

*Frontend layer:*
```bash
artillery run Code/client/src/tests/stresstests/stress_client.yml
```

*Backend layer:*
```bash
artillery run Code/server/src/tests/stresstests/stress_server.yml
```

To learn more about Amazon ECS Autoscaling, please take a look to [this](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html) documentation.
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
