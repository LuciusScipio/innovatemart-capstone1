# Development Guide

This guide outlines the step-by-step procedures to deploy, verify, and interact with the Project Bedrock microservices infrastructure. It details how to initialize your Terraform core components, resolve typical account boundaries, handle database configurations, and trigger your automated resource pipelines.

---

# Phase 1: Infrastructure Provisioning (Terraform)

Before deploying the microservices, the underlying core AWS networking, security, and cluster configurations must be initialized and brought to a steady state.

## 1. Initialize and Check the Workspace

Log in to your local terminal, navigate to your root configuration folder, and prepare your working directory:

```powershell
cd .\terraform\
terraform init
```

## 2. Run the Dry-Run Execution Plan

Generate and inspect an execution plan to ensure the configurations align with the design specification:

```powershell
terraform plan
```

## 3. Deploy the Core Topology

Apply the plan to construct your VPC tiers, internal subnets, security groups, and EKS clusters:

```powershell
terraform apply
```

> **Note:** Type `yes` when prompted to approve resource creation.

---

# Phase 2: Sourcing the Application Manifests

The `retail-store-sample-app` is structured as a collection of modular Kubernetes microservices. Rather than using an external hosted repository endpoint, you should source the raw configurations directly.

## Unified Manifest Track

Download the complete pre-packaged architecture manifest:

```bash
curl -L https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml -o retail-app-manifests.yaml
```


---

# Phase 3: Application Deployment & Database Integration

To integrate the microservices with persistent data storage, update the default application configurations to use your managed AWS services.

## 1. Update Endpoint Environment Variables

Modify the deployment configuration blocks in your manifest `retail-app-manifests.yaml` file.

### Catalog Service

Configure the Catalog service to use your Amazon RDS MySQL instance:

- Endpoint: Amazon RDS MySQL
- Port: `3306`

### Orders Service

Configure the Orders service to use your Amazon RDS PostgreSQL instance:

- Endpoint: Amazon RDS PostgreSQL
- Port: `5432`

### Carts Service

Configure the Carts service to use Amazon DynamoDB:

- Table Name: `project-bedrock-carts`
- Authentication: IAM Roles for Service Accounts (IRSA)

## 2. Deploy the Application


```bash

aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster

kubectl create namespace retail-space  

kubectl apply -f retail-app-manifests.yaml -n retail-space          
```

---

# Phase 4: Verification & Application Access

After deployment completes successfully, verify connectivity and retrieve the application URL.

## 1. Retrieve the Load Balancer URL


```bash
kubectl get service ui -n retail-space
```

Locate the value in the **EXTERNAL-IP** column:

```text
e.g: a1234567890.us-east-1.elb.amazonaws.com
```



> **Note:** Allow 2–3 minutes for AWS Elastic Load Balancer target health checks to complete before accessing the application.

## 2. Verify Serverless Automation & Observability

### Test S3 Event Processing

Upload a test file into:

```text
bedrock-assets-your-id
```

> Ensure the bucket name remains lowercase to satisfy DNS naming requirements.

### Verify Lambda Execution

Navigate to the AWS Lambda Console and confirm that EventBridge triggers execute successfully.

### Monitor Logs and Metrics

Navigate to Amazon CloudWatch and review:

- Application log groups
- Lambda logs
- Container logs
- Infrastructure metrics

---

# Phase 5: Triggering and Running the Pipeline

For continuous operations and infrastructure updates, you can trigger deployments manually or automatically through GitHub Actions.

## 1. Manual Pipeline Execution

### Format and Validate Terraform

```powershell
terraform fmt
terraform validate
```

### Refresh Infrastructure State

```powershell
terraform apply -refresh-only
```

### Deploy Infrastructure Changes

```powershell
terraform apply --auto-approve
```

---

## 2. Automated CI/CD Pipeline (GitHub Actions)

Create the following workflow:

**File Location**

```text
.github/workflows/deploy.yml
```

### Workflow Definition

```yaml
name: "Project Bedrock Infrastructure Pipeline"

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  terraform:
    name: "Apply Infrastructure Map"
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Setup Terraform Engine
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init & Apply
        run: |
          cd terraform
          terraform init
          terraform apply --auto-approve
```
> **Note:** Rememer to configure your Github secrets for `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
---

## 3. Triggering the Automation Workflow

### Automatic Trigger

Push changes to the main branch:

```bash
git add .
git commit -m "Update infrastructure"
git push origin main
```

GitHub Actions will automatically start the deployment workflow.

### Manual Trigger

1. Open your GitHub repository.
2. Select the **Actions** tab.
3. Click **Project Bedrock Infrastructure Pipeline**.
4. Click **Run workflow**.
5. Select the target branch.
6. Click **Run workflow**.

The workflow will begin immediately and apply the infrastructure changes.

---

# Deployment Flow Summary

```text
Terraform Init
      ↓
Terraform Plan
      ↓
Terraform Apply
      ↓
Configure Databases
      ↓
Create namespace & apply manifest
      ↓
Verify Services
      ↓
Retrieve Load Balancer URL
```
