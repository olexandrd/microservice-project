# Lesson 5: Terraform Project

This directory contains the source code and resources for Lesson 5, focusing on Terraform infrastructure as code.
IaS creates a VPC with public and private subnets, one NAT Gateway, route tables, an ECR repository, and configures a remote backend using S3 and DynamoDB for state management.

Below is an overview of the contents:

## Directory Structure

```plaintext
lesson-5/
│
├── main.tf                 
├── backend.tf              
├── outputs.tf             
├── modules/                
│   │
│   ├── s3-backend/
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── ecr/
│       ├── ecr.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── README.md

```

## Contents

- **main.tf**: Main Terraform configuration file.
- **variables.tf**: Defines input variables for the Terraform project.
- **outputs.tf**: Specifies output values from the Terraform deployment.
- **README.md**: Documentation.

### Getting Started

1. **Initialize Terraform**  
    From the `lesson-5` directory, initialize the project:

    ```bash
    terraform init
    ```

2. **Plan Infrastructure**  
    Review the planned changes:

    ```bash
    terraform plan
    ```

3. **Apply Configuration**  
    Deploy the infrastructure:

    ```bash
    terraform apply
    ```

4. **Destroy Infrastructure**
    To remove the deployed resources, run:

    ```bash
    terraform destroy
    ```

### Notes

- Ensure Terraform is installed and configured on your system.
- Modify the `.tf` files as needed for your infrastructure requirements.
