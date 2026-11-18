#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
ZONE_ID="Z1013544R9WOGN2CLNJ9"
DOMAIN_NAME="venkatcloudstack.shop"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# all instances managed by this script
ALL_INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "frontend")

#### validation ####
if [ $# -lt 2 ]; then
    echo -e "${R}ERROR: at least two args required${N}"
    echo "USAGE: $0 [create/destroy] [all | instance1 instance2 ...]"
    exit 1
fi

ACTION=$1
shift   # remove first argument

# accept "delete" as an alias of "destroy"
[ "$ACTION" == "delete" ] && ACTION="destroy"

if [ "$ACTION" != "create" ] && [ "$ACTION" != "destroy" ]; then
    echo -e "${R}ERROR: first arg must be either create or destroy${N}"
    echo "USAGE: $0 [create/destroy] [all | instance1 instance2 ...]"
    exit 1
fi

# if the user typed "all" (any case), use the full list
if [ "${1,,}" == "all" ]; then
    INSTANCES=("${ALL_INSTANCES[@]}")
else
    INSTANCES=("$@")
fi

echo -e "${Y}Action: $ACTION | Instances: ${INSTANCES[*]}${N}"

get_instance_id(){
    name="$1"
    aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=roboshop-$name" "Name=instance-state-name,Values=pending,running" \
        --query "Reservations[0].Instances[0].InstanceId" --output text
}

for instance in "${INSTANCES[@]}"
do
    INSTANCE_ID=$(get_instance_id "$instance")

    if [ "$ACTION" == "create" ]; then

        if [ "$INSTANCE_ID" == "None" ]; then
            echo "launching instance: roboshop-$instance"
            INSTANCE_ID=$(aws ec2 run-instances \
                --image-id "$AMI_ID" \
                --instance-type t3.micro \
                --security-groups "roboshop-common" "roboshop-$instance" \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
                --query "Instances[0].InstanceId" \
                --output text)
            echo "launched instance: $INSTANCE_ID"
        else
            echo "roboshop-$instance already running: $INSTANCE_ID"
        fi

        # wait so the IP address is available
        aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

        ## update R53 record
        if [ "$instance" == "frontend" ]; then
            IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                --output text)
            R53_RECORD="$DOMAIN_NAME"
        else
            IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                --output text)
            R53_RECORD="$instance.$DOMAIN_NAME"
        fi

        aws route53 change-resource-record-sets \
            --hosted-zone-id "$ZONE_ID" \
            --change-batch '
            {
                "Comment": "Update DNS records",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": "'"$R53_RECORD"'",
                            "Type": "A",
                            "TTL": 1,
                            "ResourceRecords": [
                                { "Value": "'"$IP"'" }
                            ]
                        }
                    }
                ]
            }' >/dev/null
        echo -e "${G}updated r53 record for: $instance ($R53_RECORD -> $IP)${N}"

    else
        if [ "$INSTANCE_ID" == "None" ]; then
            echo "$instance already destroyed, nothing to do"
        else
            aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" >/dev/null
            echo "terminating instance: $instance ($INSTANCE_ID)"
        fi
    fi
done