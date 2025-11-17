# 🌐 DevOps Infrastructure & CI/CD Full Guide

This README provides a complete, step-by-step workflow covering:

- Containerizing an application with Docker  
- Provisioning infrastructure on AWS using Terraform  
- Creating a GitHub Actions pipeline for infrastructure automation  
- Creating a GitHub Actions pipeline for application build, push, and deployment via SSH  

---

# 📚 Summary

- [🚀 Step 1 — Dockerfile: Building the Application Image](#-step-1--dockerfile-building-the-application-image)
- [🏗️ Step 2 — Provisioning Infrastructure with Terraform](#-step-2--provisioning-infrastructure-with-terraform)
- [⚙️ Step 3 — Provisioning Repository with Terraform](#-step-3--provisioning-repository-with-terraform)

---

# 🚀 Step 1 – Dockerfile: Building the Application Image

The application is a static website containing **HTML, CSS, and JavaScript**.  
To serve it efficiently, we'll use **Nginx**.

### ✔️ Example Dockerfile

```dockerfile
FROM nginx:alpine
COPY website/ /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```
- nginx:alpine → Lightweight base image ideal for containers
- COPY → Moves website files into Nginx's webroot
- EXPOSE 80 → Publishes port 80
- daemon off → Forces Nginx to run in the foreground (required for Docker)

#  🏗️ Step 2 — Provisioning Infrastructure with Terraform

Terraform is used to provision and manage all cloud resources required for the application. By defining infrastructure as code, the environment becomes consistent, reproducible, and easy to automate.


### ** `bootstrap/` — Terraform Backend Bootstrap**

Create a directory called **`bootstrap/`**.  
This folder contains the **Terraform configuration files (`.tf`)** responsible for creating the S3 bucket used as the Terraform remote backend.

⚠️ **Important:**  
Terraform cannot use the S3 backend until the bucket **already exists**.  
Therefore, this bootstrap step is required before running `terraform init` inside the main infrastructure.

---

### ** `infrastructure/` — Main Terraform Infrastructure**

Create a directory called **`infrastructure/`**.  
This folder stores all Terraform files used to provision the main AWS infrastructure, including:

- EC2 instance  
- Security Groups  
- IAM roles and instance profiles  
- ECR repository  
- Networking resources  
- User Data scripts  
- Any additional AWS components needed by the application  

This directory represents your primary Terraform stack.

---

---

### ** `.github/workflows/` — GitHub Workflows**

Create a directory called **`.github/workflows/`**.  
This folder stores all **GitHub Actions workflow files (`.yml`)**.

GitHub automatically detects and runs any workflow placed inside it, enabling:

- CI/CD pipelines  
- Docker image builds  
- Terraform deployment automation  

---

### 🔧 Bootstrap

#### ✔️ S3
Before using Terraform to provision infrastructure, you must prepare a remote backend to store the Terraform state file (tfstate).

This bucket allows Terraform to maintain the state remotely, enabling team collaboration, state locking, and preventing conflicts during deployments.

Inside the `bootstrap/` directory, create a file named `backend_bucket.tf`.

### 🔧 Infrastructure

#### ✔️ AWS Provider
The **AWS Provider** is the component in Terraform that enables interaction with Amazon Web Services.  
It acts as the bridge between Terraform and AWS, allowing Terraform to create, modify, and manage AWS resources such as EC2, S3, IAM, ECR, and more.

The provider configuration defines essential settings, such as the AWS region where resources will be deployed:

Inside the `infrastructure/` directory, create a file named `provider.tf`.

#### ✔️ Amazon ECR (Elastic Container Registry)
A private Docker image registry. Terraform creates the ECR repository where the CI/CD pipeline will push application images.

Inside the `infrastructure/` directory, create a file named `ecr.tf`.


#### ✔️ EC2 Instance
A virtual machine responsible for pulling the Docker image from ECR and running the application container.  
Terraform will configure:

- Instance type and AMI  
- Networking  
- IAM Roles  
- User Data for automated deployment  

Inside the `infrastructure/` directory, create a file named **`ec2.tf`** to store all EC2-related configurations.

---

#### Security Groups
Security Groups define the firewall rules that control inbound and outbound traffic.  
They ensure the EC2 instance receives only the required traffic (for example, HTTP on port 80).

Add all Security Group configurations **inside the same `ec2.tf` file** located in the `infrastructure/` directory.

---

#### User Data
User Data is a bootstrap script executed automatically when the EC2 instance starts.  
This script typically:

- Installs Docker  
- Logs in to Amazon ECR  
- Pulls the latest application image  
- Runs the container  

Inside the `infrastructure/` directory:

- Create a file named **`user_data.sh`**  
- Reference this script inside **`ec2.tf`**

---

#### IAM Attachments
Terraform assigns the necessary IAM role, policies, and instance profile so the EC2 instance can:

- Authenticate with Amazon ECR  
- Pull private container images  
- Access required AWS services  

All IAM Role, Policy, and Instance Profile configurations should also be included inside the **`ec2.tf`** file in the `infrastructure/` directory.



#### ✔️ Remote Terraform Backend (tfstate)
The Terraform state file is stored remotely (e.g., S3 + DynamoDB). This provides:
- Centralized state storage  
- Versioning  
- Locking to prevent concurrent modifications  
- Team-friendly workflows

Inside the `infrastructure/` directory, create a file named `backend.tf`.


### 🔧 GitHub Actions Pipeline for Infrastructure

Inside the `.github/workflows` directory, create a file named `terraform.yaml`.

This workflow automates the complete Terraform lifecycle using GitHub Actions, including:

- Initializing the backend
- Creating the S3 bucket required for the remote backend (bootstrap phase)
- Provisioning the main infrastructure
- Conditional execution of apply, plan destroy, and destroy actions
- The workflow is triggered manually through workflow_dispatch, allowing full control over infrastructure operations.

### Job Steps Explained

#### 🛒 1. Checkout
```
- name: Checkout
  uses: actions/checkout@v5.0.0
```
Clones the repository into the runner, making the Terraform files available for execution.

#### 🔐 2. Configure AWS Credentials
```
- name: "Configure AWS Credentials"
  uses: aws-actions/configure-aws-credentials@v4.3.1
```
Authenticates GitHub Actions in AWS using an IAM Role.
Required for Terraform to interact with AWS resources

#### 🧱 3. Setup Terraform
```
- name: HashiCorp - Setup Terraform
  uses: hashicorp/setup-terraform@v3.1.2
```
Installs the Terraform CLI on the runner.

#### 🚀 4. Backend (S3 Bucket)

```
- name: Terraform Init (bootstrap)
  working-directory: ./bootstrap
  run: terraform init
```

Creates the S3 bucket that will be used as the backend for the main infrastructure.

#### 🔧 5. Infrastructure Phase — Main Provisioning

```
- name: Terraform Init (infra)
  working-directory: ./infrastructure
  run: terraform init -migrate-state
```

Creates the main infrastructure.
