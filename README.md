# n8n DevOps Orchestrator - Stage 3

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
Fire 15 concurrent messages from your VM to verify the logic:
```
for i in {1..15}; do
  curl -X POST "http://localhost:5678/webhook-test/devops-alert" \
  -H "Content-Type: application/json" \
  -d "{\"severity\": \"critical\", \"message\": \"Alert #$i\", \"id\": $i}" &
done; wait
```

## Stage 3: Scaling & Reliability (Queue Mode)

To handle high-concurrency DevOps workloads, the architecture has been upgraded from "Main" mode to **Queue Mode**. This decouples the UI from the execution engine.

### Architecture Components
* **Redis:** Acts as the message broker (Bull) to manage the task queue.
* **Main Process:** Handles the Web UI and API requests.
* **Workers:** Dedicated containers that process the actual workflow logic.

### Scaling Instructions

1.  **Generate Encryption Key:**
    n8n requires a persistent encryption key to synchronize data between the Main process and Workers.
    ```bash
    openssl rand -hex 24
    ```
    Add this value to your `.env` file as `N8N_ENCRYPTION_KEY`.

2.  **Deploy the Distributed Stack:**
    ```bash
    docker compose up -d
    ```

3.  **Horizontal Scaling:**
    To increase processing power (e.g., handling 15+ concurrent webhooks), scale the worker service:
    ```bash
    docker compose up -d --scale worker=2
    ```

4.  **Verification:**
    Check the cluster status in the UI under **Settings > Queue**. You should see multiple active workers listed.
