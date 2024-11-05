#!/bin/bash

# Define the CloudFormation stack name
STACK_NAME="GGWorkshopFleetProvisioning"
TEMPLATE_FILE="template.yaml"

# Define output file paths
CERT_DIR="claim-certs"
CERT_PEM_OUTFILE="$CERT_DIR/claim.pem.crt"
PUBLIC_KEY_OUTFILE="$CERT_DIR/claim.public.pem.key"
PRIVATE_KEY_OUTFILE="$CERT_DIR/claim.private.pem.key"
POLICY_NAME="GGWorkshopProvisioningClaimPolicy"

# Create the CloudFormation stack
echo "Creating CloudFormation stack: $STACK_NAME..."
aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://$TEMPLATE_FILE --capabilities CAPABILITY_NAMED_IAM

# Check the creation status
echo "Waiting for CloudFormation stack creation to complete..."
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME

# Verify the stack status
STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text)
if [ "$STATUS" == "CREATE_COMPLETE" ]; then
    echo "CloudFormation stack $STACK_NAME created successfully."
else
    echo "Error: Stack $STACK_NAME creation failed with status: $STATUS"
    exit 1
fi

# Create the claim-certs directory if it doesn't exist
mkdir -p $CERT_DIR

# Step 1: Create the certificate and keys
echo "Creating certificate and keys..."
CERT_ARN=$(aws iot create-keys-and-certificate \
  --certificate-pem-outfile "$CERT_PEM_OUTFILE" \
  --public-key-outfile "$PUBLIC_KEY_OUTFILE" \
  --private-key-outfile "$PRIVATE_KEY_OUTFILE" \
  --set-as-active \
  --query 'certificateArn' \
  --output text)

if [ -z "$CERT_ARN" ]; then
    echo "Error: Failed to create certificate."
    exit 1
else
    echo "Certificate created successfully with ARN: $CERT_ARN"
fi

# Step 2: Attach the IoT policy to the claim certificate
echo "Attaching policy $POLICY_NAME to the certificate..."
aws iot attach-policy --policy-name "$POLICY_NAME" --target "$CERT_ARN"

if [ $? -eq 0 ]; then
    echo "Policy $POLICY_NAME successfully attached to certificate."
else
    echo "Error: Failed to attach policy."
    exit 1
fi

echo "Certificate and policy setup completed."



