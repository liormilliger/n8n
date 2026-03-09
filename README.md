# n8n DevOps Orchestrator - Stage 5: The Infrastructure Sentinel

This repository manages a distributed, auto-scaling n8n cluster on AWS designed to process real-time webhooks
and audit cloud resources (S3, EBS, and Security Groups).

## 1. Infrastructure Provisioning

### Step A: Deploy the CloudStack

Use your `n8n-infra.yaml` to launch the EC2 instance and create the scoped IAM user (`n8n-cloud-auditor`).

```bash
aws cloudformation create-stack \
  --stack-name n8n-devops-stage5 \
  --template-body file://n8n-infra.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=KeyName,ParameterValue=n8n-infra
```

### Step B: Retrieve Vault Credentials

Once the stack is `CREATE_COMPLETE`, grab your Access Keys for the n8n UI:

```bash
aws cloudformation describe-stacks --stack-name n8n-devops-stage5 --query "Stacks[0].Outputs"
```

---

## 2. Server Deployment (The Cluster)

1. **SSH into the VM:** `ssh -i n8n-infra.pem ubuntu@<EC2-IP>`
2. **Setup Folder:** `mkdir n8n-config && cd n8n-config`
3. **Environment Setup:** Create a `.env` file. Generate a key with `openssl rand -hex 24` for `N8N_ENCRYPTION_KEY`.
4. **Launch with Workers:** This command starts the Main UI and 2 Workers for parallel processing.

```bash
docker compose up -d --scale worker=2
```

---

## 3. Workflow Logic: Node-by-Node Guide

### A. Real-Time Alert Webhook

* **Webhook Node:** HTTP Method: `POST`, Path: `devops-alert`.
* **Filter Node:** Condition: `{{ $json.body.severity }}` equals `critical`.
* **Code Node:**
```javascript
for (const item of $input.all()) {
  item.json.processed_at = new Date().toISOString();
  item.json.status = "DISPATCHED";
}
return $input.all();
```

### B. S3 Inventory Audit

* **AWS S3 Node:** Resource: `Bucket`, Operation: `Get All`.
* **Credential:** Use the keys from your CloudFormation output.

### C. EBS "Zombie" Hunter (HTTP Chain)

1. **HTTP Request Node:**
* **URL:** `https://ec2.us-east-1.amazonaws.com/?Action=DescribeVolumes&Version=2016-11-15`
* **Auth:** AWS Signature v4.
2. **XML Node:** Action: `To JSON`, Property: `data`.
3. **Code Node (Flattening):**

```javascript
const items = $input.first().json.DescribeVolumesResponse.volumeSet.item;
return items.map(v => ({ json: v }));
```

### D. Security Group "Gatekeeper" (HTTP Chain)

1. **HTTP Request Node:**
* **URL:** `https://ec2.us-east-1.amazonaws.com/?Action=DescribeSecurityGroups&Version=2016-11-15`
* **Auth:** AWS Signature v4.


2. **XML Node:** Action: `To JSON`, Property: `data`.
3. **Code Node (Security Logic):**

```javascript
const sgs = $input.first().json.DescribeSecurityGroupsResponse.securityGroupInfo.item;
let rules = [];
sgs.forEach(sg => {
  const perms = Array.isArray(sg.ipPermissions.item) ? sg.ipPermissions.item : [sg.ipPermissions.item];
  perms.forEach(p => {
    rules.push({ json: { name: sg.groupName, port: p.fromPort, cidr: p.ipRanges.item } });
  });
});
return rules;
```

---

## 4. Teardown

To practice the "Fresh Start" methodology:

```bash
aws cloudformation delete-stack --stack-name n8n-devops-stage5
```