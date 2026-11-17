#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
ZONE_ID="Z1013544R9WOGN2CLNJ9"
DOMAIN_NAME="venkatcloudstack.shop"

for instance in "$@"
do
    echo "launching instance : $instance"
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id ami-0055977a6e828a4f4 \
        --instance-type t3.micro \
        --security-groups "roboshop-common" "roboshop-$instance"\
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value='roboshop-$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text
    )
    echo "instance ID : $INSTANCE_ID"
    if [ "$instance" == "frontend" ]; then
        IP=$( aws ec2 describe-instances --instance-ids $INSTANCE_ID \
         --query 'Reservations[0].Instances[0].PublicIpAddress '   \
         --output text
            )
        R53_RECORD="$DOMAIN_NAME"

    else 
        IP=$( aws ec2 describe-instances --instance-ids $INSTANCE_ID \
         --query 'Reservations[0].Instances[0].PrivateIpAddress'    \
         --output text
            )
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
                        "Name": "'$R53_RECORD'",
                        "Type": "A",
                        "TTL": 1,
                        "ResourceRecords": [
                            {
                                "Value": "'$IP'"
                            }
                        ]
                    }
                }
            ]
        }

        
    '


done