# n8n DevOps Orchestrator - Stage 2

This repository contains the Infrastructure as Code (CloudFormation) and container orchestration (Docker Compose) for a production-grade n8n automation server.

## Architecture
- **Cloud:** AWS (us-east-1)
- **OS:** Ubuntu 24.04 LTS
- **Engine:** n8n (Latest)
- **Database:** Postgres 16

## Prerequisites
1. AWS CLI configured with appropriate permissions.
2. A KeyPair named `lior-inbal` in `us-east-1`.
3. An existing Security Group (`sg-0d0da3384972f4851`).

## Setup Instructions

### 1. Provision Infrastructure
Deploy the CloudFormation stack:
```
aws cloudformation create-stack \
  --stack-name n8n-devops-stage2 \
  --template-body file://n8n-infra.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=lior-inbal
```

### 2. Deploy Application
1. SSH into the instance.
2. Create `docker-compose.yaml` and `.env`.
3. Launch: `docker compose up -d`.

### 2.5 UI Configuration (The "Logic" Layer)
Before testing, you must configure the workflow in the browser:
1. **Access:** Open `http://<EC2-IP>:5678` and log in.
2. **Create Workflow:** Click "Add Workflow" and name it `DevOps-Alert-Processor`.
3. **Nodes Setup:**
    * **Webhook:** Set Method to `POST` and Path to `devops-alert`.
    * **Filter:** Add a condition where `{{ $json.body.severity }}` equals `critical`.
    * **Code (JS):** Connect to the "True" path of the Filter and paste the transformation script.
4. **Activation:** Click **Execute Workflow** (at the bottom) to put the canvas into "Listen" mode.

### 3. Test Workflow (Stress Test)
Fire 5 concurrent messages from your VM to verify the logic:
```bash
for i in {1..5}; do
  curl -X POST "http://localhost:5678/webhook-test/devops-alert" \
  -H "Content-Type: application/json" \
  -d "{\"severity\": \"critical\", \"message\": \"Alert #$i\", \"id\": $i}" &
done; wait
