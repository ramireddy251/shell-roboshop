

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0f8e049cbcce85622"
INSTANCE_TYPE="t3a.micro"

for instance in $@
do

instance_id=$( aws ec2 run-instances \
--image-id $AMI_ID \
--instance-type $INSTANCE_TYPE \
--security-group-ids $SG_ID \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
--query 'Instances[0].InstanceId.PrivateIpAddress' \
--output text )

if [ $instance_id == "frontend" ]; then
IP=$(

    aws ec2 describe-instances \ 
    --instance-ids $instance_id \ 
    --query 'Reservations[].Instances[].PublicIpAddress' \ 
    --output text

)
else
 IP=$(

    aws ec2 describe-instances \ 
    --instance-ids $instance_id \ 
    --query 'Reservations[].Instances[].PrivateIpAddress' \ 
    --output text

) 
fi

echo "IP address: $IP"
done
