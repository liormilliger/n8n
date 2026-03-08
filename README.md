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
```bash
aws cloudformation create-stack \
  --stack-name n8n-devops-stage2 \
  --template-body file://n8n-infra.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=lior-inbal