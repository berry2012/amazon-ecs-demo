# Step 1 - Deploy Cluster and Mock services in default VPC

export REGION="eu-west-1"
export ENVIRONMENT_NAME="ecs-bootcamp"
export CONTAINER_NAME="runtime-demo"


# substitue values with your own values
aws --region "${REGION}" \
    cloudformation deploy \
    --stack-name "${ENVIRONMENT_NAME}" \
    --capabilities CAPABILITY_IAM \
    --template-file "resource.yaml"  \
    --parameter-overrides \
    EnvironmentName="${ENVIRONMENT_NAME}" \
    VPC="vpc-0669fe0753d52505f" \
    PublicSubnet1="subnet-0ce55968e98859021" \
    PublicSubnet2="subnet-0d226964c71f8234e"


aws cloudformation describe-stacks --stack-name "${ENVIRONMENT_NAME}" --query Stacks\[\].StackStatus  --output text

# Clean up
aws --region "${REGION}" \
    cloudformation delete-stack \
    --stack-name "${ENVIRONMENT_NAME}" \


