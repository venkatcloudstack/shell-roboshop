#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
ZONE_ID="Z1013544R9WOGN2CLNJ9"
DOMAIN_NAME="venkatcloudstack.shop"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#### validation ####
if [ $# -lt 2 ]; then
    echo -e "$R ERROR: atleast two args required $N"
    echo "USAGE: $0 [create/destroy] [instance1] [instance2]"
    exit 1
fi

ACTION=$1
shift  ##first argument will be removed
 
if [ $ACTION -! create ] && [ $ACTION -! delete ]; then
    echo -e " $R ERROR: first arg must be either create or delete $N "
    echo "USAGE: $0 [create/destroy] [instance1] [instance2]"
    exit 1
fi

get_instance_id(){
    name=$1
    aws ec2 describe-instances   --filters "Name=tag:Name,Values=roboshop-$name" "Name=instance-state-name,Values=running"   --query "Reservations[0].Instances[0].InstanceId" --output text

}

for instance in $@
do
    INSTANCE_ID=$(get_instance_id $instance)
    if [ "$ACTION" == "create" ]; then
        if [ "$INSTANCE_ID" == "none" ];then
            echo "launching instance :roboshop-$instance"
             INSTANCE_ID=$(aws ec2 run-instances \
            --image-id ami-0055977a6e828a4f4 \
            --instance-type t3.micro \
            --security-groups "roboshop-common" "roboshop-$instance"\
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
            --query "Instances[0].InstanceId" \
            --output text
             )
             echo "launched instance: $INSTANCE_ID "
        else
            echo "roboshop-$instance already running : $INSTANCE_ID"
        fi
    fi
    
done