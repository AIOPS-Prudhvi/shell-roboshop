#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
ZONE_ID="Z0970256W74FS2R5N49F"
DOMAIN_NAME="prudhvi.store"

R="\e[31m"
G="\e[32m"  
Y="\e[33m"
N="\e[0m"   

### Validation ### 

if [ $# -lt 2 ]; then
    echo -e " $R [ERROR]::  Atleast pass two arguments to the script $N"
    echo "USAGE: $0 [create/delete] [instance1] [instance2] [instance3] ..."
    exit 1
fi

ACTION=$1
shift # The command shift means ther first argument is removed from the list of arguments and the second argument becomes the first argument. This is useful when you want to process a list of arguments one at a time.

if [ "$ACTION" != "create" ] && [ "$ACTION" != "delete" ]; then ## != or -ne is not equal to
    echo -e " $R [ERROR]:: Invalid action $ACTION. Please use 'create' or 'delete' $N"
    echo "USAGE: $0 [create/delete] [instance1] [instance2] [instance3] ..."
    exit 1
fi

get_instance_id() {
    local instance_name=$1
    aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance_name" --query "Reservations[*].Instances[*].InstanceId" --output text
}

for instance in $@
do
    INSTANCE_ID=$(get_instance_id "roboshop-$instance")  
    if [ "$ACTION" == "create" ]; then
        if [ $INSTANCE_ID == "None" ]; then
            echo -e " $G [INFO]:: Launching instance: roboshop-$instance $N"
            INSTANCE_ID=$(aws ec2 run-instances \
                --image-id $AMI_ID \
                --instance-type t3.micro \
                --security-groups "roboshop-common" "roboshop-$instance" \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
                --query 'Instances[0].InstanceId' \
                --output text
            )
            echo -e " $G [INFO]:: Instance ID: $INSTANCE_ID $N"
            
            if [ $instance == "frontend" ]; then
                IP=$(aws ec2 describe-instances \
                    --instance-ids $INSTANCE_ID \
                    --query 'Reservations[0].Instances[0].PublicIpAddress' \
                    --output text
                )
                R53_RECORD="$DOMAIN_NAME"
            else
                IP=$(aws ec2 describe-instances \
                    --instance-ids $INSTANCE_ID \
                    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                    --output text
                )
                R53_RECORD="$instance.$DOMAIN_NAME"
            fi

            aws route53 change-resource-record-sets \
                --hosted-zone-id $ZONE_ID \
                --change-batch '{
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
                }'
            echo -e " $G [INFO]:: Route53 record for $R53_RECORD updated with IP: $IP $N"
        else
            echo -e " $Y [INFO]:: Instance roboshop-$instance already exists with ID: $INSTANCE_ID. Skipping creation. $N"
        fi
    elif [ "$ACTION" == "delete" ]; then
        if [ $INSTANCE_ID != "None" ]; then
            echo -e " $G [INFO]:: Terminating instance: roboshop-$instance with ID: $INSTANCE_ID $N"
            aws ec2 terminate-instances --instance-ids $INSTANCE_ID
            echo -e " $G [INFO]:: Instance roboshop-$instance with ID: $INSTANCE_ID has been terminated. $N"
        else
            echo -e " $Y [INFO]:: Instance roboshop-$instance does not exist. Skipping termination. $N"
        fi
    fi    
            
done