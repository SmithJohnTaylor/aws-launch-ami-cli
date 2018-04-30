#!/bin/bash

java -jar ./oktaAWSCLI.jar

####### USER SPECIFIC CONFIGS #######
REGION="us-east-1"                  #
AMI_ID=""               #
INSTANCE_TYPE="m5.xlarge"           #
LOCALPATHTOKEYS="~/keys"            #
SECURITY_GROUP=""        #
SUBNET_ID=""         #
USER_DATA_FILE="userdata.txt"       #
#####################################

echo "What's your name?"
read USERNAME
echo "What do you want to name the instance?"
read INSTANCE_NAME
echo "What is the name of your key-pair? (Do not include the extension)"
read KEYPAIR

LAUNCH=$(aws ec2 run-instances --region $REGION \
--image-id $AMI_ID \
--count 1 \
--user-data file://$USER_DATA_FILE \
--instance-type $INSTANCE_TYPE \
--key-name $KEYPAIR \
--security-group-ids $SECURITY_GROUP \
--subnet-id $SUBNET_ID \
--tag-specifications 'ResourceType=instance,Tags=[{Key="Name",Value='"$INSTANCE_NAME"'},{Key="SE Name",Value='"$USERNAME"'}]')

echo
echo Instance launched.
INSTANCE_ID=$(echo $LAUNCH| awk -F'InstanceId\": "' '{ print $2}'|awk -F '\"' '{ print $1 }')

times=0
echo
echo Attempting to verify Instance: $INSTANCE_ID is running...
while [ 20 -gt $times ] && ! aws ec2 describe-instances --region $REGION --filters "Name=instance-id,Values=$INSTANCE_ID" | grep -q "running"
do
  times=$(( $times + 1 ))
done

if [ 20 -eq $times ]; then
  echo Instance $INSTANCE_ID is not running. Exiting...
  exit
else
  echo
  echo Instance $INSTANCE_ID is running.
fi

SSH_IP=$(aws ec2 describe-instances --region $REGION \
--filters "Name=instance-id,Values=$INSTANCE_ID" \
--query 'Reservations[*].Instances[*].PublicIpAddress[]' --output text)

echo
echo Connect to your instance using the following command:
echo ssh -i $LOCALPATHTOKEYS/$KEYPAIR.pem ec2-user@$SSH_IP
echo
echo Script complete.
#CONNECT=$(ssh -oStrictHostKeyChecking=no -i ~/keys/$KEYPAIR.pem ec2-user@$SSH_IP)
