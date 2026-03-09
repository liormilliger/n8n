# 1. Capture your IP
MY_IP=$(curl -s http://checkip.amazonaws.com)/32

# 2. Fire up the stack
aws cloudformation create-stack \
  --stack-name n8n-devops-stage5-1 \
  --template-body file://n8n-infra.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=KeyName,ParameterValue=lior-inbal \
    ParameterKey=AdminIP,ParameterValue=$MY_IP

# Get the IP from the stack output
SERVER_IP=$(aws cloudformation describe-stacks --stack-name n8n-devops-stage5-1 --query "Stacks[0].Outputs[?OutputKey=='InstancePublicIP'].OutputValue" --output text)

ssh -i n8n-infra.pem ubuntu@$SERVER_IP

