# n8n DevOps Orchestrator - Stage 4: Cloud-Integrated Sentinel

This repository orchestrates a production-grade, distributed n8n cluster.
It features automated IAM management and a dual-purpose logic engine:
Real-time Alert Processing and Cloud Resource Auditing.

## Architecture
- **Infrastructure:** AWS EC2 (t3.medium) + Ubuntu 24.04
- **Orchestration:** n8n Queue Mode (Main + Redis + Workers)
- **Auth:** CloudFormation-managed IAM User (`n8n-s3-sentinel`)

## 1. Provision Infrastructure
Deploy the stack with IAM capabilities:
```bash
aws cloudformation create-stack \
  --stack-name n8n-devops-stage4 \
  --template-body file://n8n-infra.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=KeyName,ParameterValue=lior-inbal

```

**Get Credentials from Outputs:**

```bash
aws cloudformation describe-stacks --stack-name n8n-devops-stage4 --query "Stacks[0].Outputs"

```

## 2. UI Logic Configurations

### Workflow A: DevOps-Alert-Processor (Real-time)

* **Webhook Node:** HTTP Method: `POST`, Path: `devops-alert`.
* **Filter Node:** Check if `{{ $json.body.severity }}` is equal to `critical`.
* **Code Node (JavaScript):**
```javascript
for (const item of $input.all()) {
  item.json.processed_at = new Date().toISOString();
  item.json.status = "DISPATCHED_TO_SLACK";
  item.json.original_severity = item.json.severity;
}
return $input.all();

```



### Workflow B: S3-Sentinel-Audit (Infrastructure)

* **Credentials:** Use the `AccessKeyId` and `SecretAccessKey` from CFN Outputs.
* **AWS S3 Node:** Resource: `Bucket`, Operation: `Get All`.
* **Filter Node:** Check if `{{ $json.Name }}` contains `test`. (Note: S3 keys are PascalCase).
* **Code Node (JavaScript):**
```javascript
for (const item of $input.all()) {
  item.json.audit_timestamp = new Date().toISOString();
  item.json.audit_status = "VERIFIED";
}
return $input.all();

```

## 3. Operations & Stress Testing

Fire 15 concurrent messages to verify Worker distribution:

```bash
for i in {1..15}; do
  curl -X POST "http://<EC2-IP>:5678/webhook-test/devops-alert" \
  -H "Content-Type: application/json" \
  -d "{\"severity\": \"critical\", \"message\": \"Alert #$i\", \"id\": $i}" &
done; wait

```

## 4. Teardown (Practice Mode)

```bash
aws cloudformation delete-stack --stack-name n8n-devops-stage4
aws cloudformation wait stack-delete-complete --stack-name n8n-devops-stage4

```
