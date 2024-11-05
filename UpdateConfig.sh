#!/bin/bash

# Define the YAML file
TEMPLATE_FILE="template.yaml"

# Function to display help
usage() {
    echo "Usage: $0 -g THING_GROUP_NAME"
    exit 1
}

# Parse command line arguments
while getopts ":g:" opt; do
    case ${opt} in
        g )
            THING_GROUP_NAME=$OPTARG
            ;;
        \? )
            usage
            ;;
    esac
done

# Check that the Thing Group Name argument is provided
if [ -z "$THING_GROUP_NAME" ]; then
    usage
fi

# Get the AWS region configured in the AWS CLI
AWS_REGION=$(aws configure get region)

# Check if AWS region is empty
if [ -z "$AWS_REGION" ]; then
    echo "AWS region is not configured in the AWS CLI."
    exit 1
fi


echo "Thing Group Name: $THING_GROUP_NAME"
echo "AWS Region: $AWS_REGION"
echo "CloudFormation Template File: $TEMPLATE_FILE"

# Check if the thing group was created
GROUP_EXISTS=$(aws iot list-thing-groups --query "thingGroups[?thingGroupName=='$THING_GROUP_NAME'] | length(@)")

if [ "$GROUP_EXISTS" -gt 0 ]; then
    echo "Thing group '$THING_GROUP_NAME' found."
else
    echo "Create a Thing Group '$THING_GROUP_NAME'."
    # Create a Thing Group
    THING_GROUP_ARN=$(aws iot describe-thing-group --thing-group-name "$THING_GROUP_NAME" --query "thingGroupArn" --output text)
fi


 
# Get the IoT Credential Endpoint
IOT_CREDENTIAL_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:CredentialProvider --query 'endpointAddress' --output text)

# Get the IoT Data Endpoint
IOT_DATA_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --query 'endpointAddress' --output text)

# Check if the endpoints are not empty
if [ -z "$IOT_CREDENTIAL_ENDPOINT" ] || [ -z "$IOT_DATA_ENDPOINT" ]; then
    echo "Failed to retrieve one or both endpoints."
    exit 1
fi

echo "Credential Endpoint: $IOT_CREDENTIAL_ENDPOINT"
echo "Data Endpoint: $IOT_DATA_ENDPOINT"



# Extract the default values for ProvisioningTemplateName and GGTokenExchangeRoleName from template.yaml
provisioningTemplate=$(grep -A 2 "ProvisioningTemplateName:" template.yaml | grep "Default:" | awk '{print $2}' | tr -d "'")
iotRoleAlias=$(grep -A 2 "GGTokenExchangeRoleName:" template.yaml | grep "Default:" | awk '{print $2}' | tr -d "'")

# Check if values were found
if [ -z "$iotRoleAlias" ] || [ -z "$provisioningTemplate" ]; then
    echo "Failed to extract one or both values."
    exit 1
fi

# Append "Alias" to the IoT Role Alias
iotRoleAlias="${iotRoleAlias}Alias"

# Output the extracted values
echo "iotRoleAlias: $iotRoleAlias"
echo "provisioningTemplate: $provisioningTemplate"



# Update the config.json file with the retrieved endpoints and Thing Group name
sed -i "s|\"iotCredentialEndpoint\": \".*\"|\"iotCredentialEndpoint\": \"$IOT_CREDENTIAL_ENDPOINT\"|" config.json
sed -i "s|\"iotDataEndpoint\": \".*\"|\"iotDataEndpoint\": \"$IOT_DATA_ENDPOINT\"|" config.json
sed -i "s|\"awsRegion\": \".*\"|\"awsRegion\": \"$AWS_REGION\"|" config.json
sed -i "s|\"ThingGroupName\": \".*\"|\"ThingGroupName\": \"$THING_GROUP_NAME\"|" config.json
sed -i "s|\"iotRoleAlias\": \".*\"|\"iotRoleAlias\": \"$iotRoleAlias\"|" config.json
sed -i "s|\"provisioningTemplate\": \".*\"|\"provisioningTemplate\": \"$provisioningTemplate\"|" config.json


echo "config.json has been updated successfully."
