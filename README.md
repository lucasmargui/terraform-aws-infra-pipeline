# 🌐 DevOps Infrastructure & CI/CD Full Guide

This README provides a complete, step-by-step workflow covering:

- Containerizing an application with Docker  
- Provisioning infrastructure on AWS using Terraform  
- Creating a GitHub Actions pipeline for infrastructure automation  
- Creating a GitHub Actions pipeline for application build, push, and deployment via SSH  

---

# 🚀 Step 1 – Dockerfile: Building the Application Image

The application is a static website containing **HTML, CSS, and JavaScript**.  
To serve it efficiently, we'll use **Nginx**.

### Example Dockerfile

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
This folder stores all **GitHub Actions workflow files (`.yaml`)**.

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

#### 1. Checkout
```
- name: Checkout
  uses: actions/checkout@v5.0.0
```
Clones this repository into the runner, making the Terraform files available for execution.

#### 2. Configure AWS Credentials
```
- name: "Configure AWS Credentials"
  uses: aws-actions/configure-aws-credentials@v4.3.1
```
Authenticates GitHub Actions in AWS using an IAM Role.
Required for Terraform to interact with AWS resources

#### 3. Setup Terraform
```
- name: HashiCorp - Setup Terraform
  uses: hashicorp/setup-terraform@v3.1.2
```
Installs the Terraform CLI on the runner.

#### 4. Backend (S3 Bucket)

```
- name: Terraform Init (bootstrap)
  working-directory: ./bootstrap
  run: terraform init
```

Creates the S3 bucket that will be used as the backend for the main infrastructure.

#### 5. Infrastructure Phase — Main Provisioning

```
- name: Terraform Init (infra)
  working-directory: ./infrastructure
  run: terraform init -migrate-state
```

Creates the main infrastructure.


# ⚙️ Step 3 — Application Pipeline (Build → Push → Deploy via SSH)

This pipeline belongs to **your application repository** — a **separate repo** from the Terraform infrastructure.  
Its job is to automate the full lifecycle of your application:

- **Build** the Docker image  
- **Push** the image to **Amazon ECR**  
- **Connect via SSH** to the EC2 instance
- **Stop** old container
- **Pull & restart** the container with the updated version

This completes the CI/CD workflow for your application.


### 📁 ** `app/` — Creating the Application Repository**

This folder contains all **application source files**, such as:

- Backend or frontend code  
- Dockerfile  
- Configuration files  
- Dependencies  


1. Create a new repository on GitHub
(Example name: my-app)

2. Clone the repository to your machine

```
git clone https://github.com/your-user/my-app.git
cd my-app
```

3. Create a new directory `app/`

### ⚙️ ** `.github/workflows/` — GitHub Workflows**

This folder stores all **GitHub Actions workflow files (`.yaml`)**.

GitHub automatically detects and runs any workflow inside this directory, enabling:

- CI/CD automation  
- Docker image build & push to ECR  
- Remote deployment via SSH

1. Create a new repository on GitHub  `.github/workflows/`
2. Create  `deploy.yaml `


### 🔧 GitHub Actions Pipeline for Repository

### 🧱 Job 1 — Build & Push to ECR

#### 1. Checkout
```
- name: Checkout
  uses: actions/checkout@v5.0.0
```
Clones the repository into the GitHub Actions runner, giving access to the Dockerfile and application code.

#### 2. Configure AWS Credentials
```
- name: "Configure AWS Credentials" 
  uses: aws-actions/configure-aws-credentials@v4.3.1
```

#### 3. Login to Amazon ECR
```
- name: Amazon ECR "Login" Action for GitHub Actions
  uses: aws-actions/amazon-ecr-login@v2.0.1
```
Authenticates GitHub Actions in AWS using an IAM role.
Required so the workflow can log in to ECR and push images.

#### 4. Build Image and Push
```
- name: Build, Tag, and Push image to Amazon ECR
  run: |
    docker build -t meu-website:v1.0 .
    docker tag meu-website:v1.0 <ID_CONTA_AWS>.dkr.ecr.<REGIAO>.amazonaws.com/site_prod:v1.0
    docker push <ID_CONTA_AWS>.dkr.ecr.<REGIAO>.amazonaws.com/site_prod:v1.0

```
This step is responsible for building the Docker image, tagging it correctly, and pushing it to the Amazon ECR repository.

- docker build generates a new image from your application's Dockerfile.
- docker tag renames the local image with the required ECR repository format.
- docker push uploads the image to your AWS ECR registry so it can be pulled later by the EC2 instance or Kubernetes cluster.

### 🚀 Job 2 — Deploy to EC2 via SSH
This job only runs after Job 1 completes successfully.

#### 🔑 Environment Variables
```
env:
  INSTANCE_KEY: ${{secrets.INSTANCE_KEY}}
  PUBLIC_IP: ${{secrets.PUBLIC_IP}}

```
Loads the EC2 SSH key and public IP stored securely in GitHub Secrets.

#### 🔌1. SSH Into EC2 and Deploy
```
- name: Deploy EC2 SSH
  run: |
    echo "$INSTANCE_KEY" > chave-site.pem
    chmod 400 chave-site.pem
    ssh -i chave-site.pem -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP << EOF
      aws ecr get-login-password --region <REGIAO> | docker login --username AWS --password-stdin <ID_CONTA_AWS>.dkr.ecr.<REGIAO>.amazonaws.com
      docker pull <ID_CONTA_AWS>.dkr.ecr.<REGIAO>.amazonaws.com/site_prod:v1.0
      echo "Stopping old container..."
      docker stop site || true
      echo "Removing old container..."
      docker rm site || true
      echo "Running new container..."
      docker run -d -p 80:80 --name site <ID_CONTA_AWS>.dkr.ecr.<REGIAO>.amazonaws.com/site_prod:v1.0
      echo "Deployment successful! The new version is live."
      docker ps
    EOF
    rm chave-site.pem

```
This step performs the full deployment:

- Logs into EC2 securely using an SSH key
- Authenticates Docker with ECR
- Pulls the latest application image
- Stops and removes the previous container (if exists)
- Runs the new version on port 80
- Prints the running containers for confirmation

This ensures a zero-downtime production update.
