
#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0f8e049cbcce85622"
INSTANCE_TYPE="t3a.micro"
ZONE_ID="Z00051682TGCBM123FIQG"
DOMAIN_MANE="ramireddy.co.in"

for instance in $@
do

INSTANCE_ID=$( aws ec2 run-instances \
--image-id $AMI_ID \
--instance-type $INSTANCE_TYPE \
--security-group-ids $SG_ID \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
--query 'Instances[0].InstanceId' \
--output text )

if [ $INSTANCE_ID == "frontend" ]; then
IP=$(
    aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text
)
RECORD_NAME="$DOMAIN_NAME" # ramireddy.co.in
else
 IP=$(
    aws ec2 describe-instances \
    --instance-ids $instance_id \
    --query 'Reservations[].Instances[].PrivateIpAddress' \
    --output text
    ) 
    RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.co.in

fi

echo "IP address: $IP"

aws route53 change-resource-record-sets \
--hosted-zone-id $ZONE_ID \
--change-batch '
    {
    "Comment": "updating record",
    "Changes": [
        {
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "'$RECORD_NAME'",
            "Type": "A",
            "TTL": 300,
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
echo "record updated for $instance"


done
