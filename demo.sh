# COPY TO CLOUD9
# Run sample task and demo GuardDuty


export REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
export ENVIRONMENT_NAME="ecs-bootcamp"
export CONTAINER_NAME="runtime-demo"

export ECS_VPC_ID=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[].VpcId' --output text --region $REGION)

export ECS_PUBLICSUBNET1_ID=$(aws cloudformation describe-stacks --stack-name ecs-bootcamp \
--region $REGION --output text \
--query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet1`].OutputValue')

export TASK_EXECUTION_ROLE=$(aws cloudformation describe-stacks --stack-name ecs-bootcamp \
--region $REGION --output text \
--query 'Stacks[0].Outputs[?OutputKey==`TaskExecutionRole`].OutputValue')

export CLUSTER_NAME="FargateCluster"

echo $ECS_PUBLICSUBNET1_ID $TASK_EXECUTION_ROLE

cat << EOF > runtime.json
{
    "family": "runtime",
    "executionRoleArn": "$TASK_EXECUTION_ROLE",
    "taskRoleArn": "$TASK_EXECUTION_ROLE",    
        "networkMode": "awsvpc",
        "containerDefinitions": [
            {
                "name": "$CONTAINER_NAME",
                "image": "nginx",
                "portMappings": [
                    {
                        "containerPort": 80,
                        "hostPort": 80,
                        "protocol": "tcp"
                    }
                ],
                "essential": true,
                "logConfiguration": {
                    "logDriver": "awslogs",
                    "options": {
                    "awslogs-create-group": "True",
                    "awslogs-group": "/ecs/$CONTAINER_NAME",
                    "awslogs-region": "$REGION",
                    "awslogs-stream-prefix": "ecs"
                    }
                },
                "linuxParameters": {
                    "initProcessEnabled": true
                }                                 
            }
        ],
        "requiresCompatibilities": [
            "FARGATE"
        ],
        "cpu": "256",
        "memory": "512"
}
EOF

TASKDEF_RUNTIME=$(aws ecs register-task-definition --cli-input-json file://runtime.json \
    --region $REGION \
    --query 'taskDefinition.taskDefinitionArn' --output text)


TASK_ID=$(aws ecs run-task \
    --cluster ${CLUSTER_NAME} \
    --task-definition ${TASKDEF_RUNTIME} \
    --region ${REGION} \
    --enable-execute-command \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$ECS_PUBLICSUBNET1_ID],securityGroups=[$ECS_SERVICE_SECURITYGROUP],assignPublicIp=ENABLED}" \
    --region $REGION \
    --query 'tasks[].taskArn' --output text)


aws ecs execute-command --cluster ${CLUSTER_NAME} \
    --task  ${TASK_ID} \
    --container ${CONTAINER_NAME} \
    --interactive \
    --command "/bin/sh"

# GuardDuty Simulations
apt update -y
apt install netcat-openbsd -y

#PrivilegeEscalation:Runtime/DockerSocketAccessed
bash -c 'nc -lU /var/run/docker.sock &'
echo SocketAccessed | nc -w5 -U /var/run/docker.sock


#PrivilegeEscalation:Runtime/RuncContainerEscape
touch /bin/runc
echo "Runc Container Escape" > /bin/runc

#PrivilegeEscalation:Runtime/CGroupsReleaseAgentModified
touch /tmp/release_agent
echo "Release Agent Modified" > /tmp/release_agent

#Execution:Runtime/ReverseShell
timeout 5s nc -nlp 1337 &
sleep 5
bash -c '/bin/bash -i >& /dev/tcp/127.0.0.1/1337 0>&1'



