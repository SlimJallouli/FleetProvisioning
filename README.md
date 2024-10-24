# Fleet Provisioning for AWS IoT Greengrass

## Overview
This project helps you set up AWS IoT Fleet Provisioning for your devices using AWS CloudFormation, claim certificates, and an IoT provisioning template. The provided template.yaml will create the necessary roles, policies, and templates for provisioning.

## Prerequisites
1. AWS CLI installed and configured.
2. Access to an AWS account with permissions to create CloudFormation stacks, IAM roles, and IoT resources.
3. jq installed for JSON processing.
4. AWS Greengrass Core software installed.

## Files

1. **setup.sh**
   - Installs and configures AWS IoT Greengrass V2 with Fleet Provisioning.
   - Generates a unique device name using the hostname and machine ID.
   - Downloads and installs necessary dependencies.
   - Copies claim certificates, installs Greengrass, and configures the system service.

2. **uninstall_greengrass.sh**
   - Stops the Greengrass service.
   - Removes the Greengrass installation and configuration files from the system.

3. **config.json**
   - Configuration file for AWS IoT Greengrass and Fleet Provisioning.
   - Sets parameters such as AWS region, claim certificate paths, IoT credential and data endpoints, role alias, and provisioning template.

4. **template.yaml**
    - Cloudformation template for configuing Greengrass Fleet Provisioning resources

## Steps

### 1. Create the CloudFormation Stack
Save the template.yaml file and create a CloudFormation stack:

```bash
aws cloudformation create-stack --stack-name GGWorkshopFleetProvisioning --template-body file://template.yaml --capabilities CAPABILITY_NAMED_IAM
```

Wait a few minutes for the resources to be created. You can check the status from the CloudFormation console or with this command:

```bash
aws cloudformation describe-stacks --stack-name GGWorkshopFleetProvisioning
```

Once the stack status is CREATE_COMPLETE, you can proceed to the next section.

### 2. Generate Claim Certificates
Claim certificates are X.509 certificates that allow devices to register as AWS IoT things and retrieve a unique X.509 device certificate for regular operations. After creating a claim certificate, attach an AWS IoT policy that permits devices to create unique device certificates and provision them using a fleet provisioning template.

#### a) Create and save a certificate and private key for provisioning
Make a directory for the claim certificate and private key:

```bash
cd ~ && mkdir ~/claim-certs
```

Run the following command to create and save a certificate and private key:

```bash
aws iot create-keys-and-certificate \
  --certificate-pem-outfile "claim-certs/claim.pem.crt" \
  --public-key-outfile "claim-certs/claim.public.pem.key" \
  --private-key-outfile "claim-certs/claim.private.pem.key" \
  --set-as-active | jq .certificateArn
```

Take note of the certificate ARN because it will be needed in the next step.

#### b) Attach the IoT Policy to the Provisioning Claim Certificate
Attach the IoT policy created with CloudFormation (GGWorkshopProvisioningClaimPolicy) to the claim certificate:

```bash
aws iot attach-policy --policy-name <GGWorkshopProvisioningClaimPolicy> --target <certificateArn>
```

Replace <certificateArn> with the ARN from the previous step.

### 3. Update the Config
Make sure your config.json looks like this:

Make sure to replace "your-iot-credential-endpoint" and "your-iot-data-endpoint" with your actual AWS IoT endpoints, which you can retrieve with the following command:

```bash
aws iot describe-endpoint --endpoint-type iot:CredentialProvider
```
```bash
aws iot describe-endpoint --endpoint-type iot:Data-ATS
```

```json
{
  "services": {
    "aws.greengrass.FleetProvisioningByClaim": {
      "configuration": {
        "awsRegion": "<Greengrass-supported-aws-region>",
        "claimCertificatePath": "/greengrass/v2/claim-certs/claim.pem.crt",
        "claimCertificatePrivateKeyPath": "/greengrass/v2/claim-certs/claim.private.pem.key",
        "iotCredentialEndpoint": "<your-iot-credential-endpoint>",
        "iotDataEndpoint": "<your-iot-data-endpoint>",
        "iotRoleAlias": "<Cloudformation-TokenExchangeRoleAlias>",
        "provisioningTemplate": "<Cloudformation-FleetProvisionTemplate>",
        "rootCaPath": "/greengrass/v2/AmazonRootCA1.pem",
        "rootPath": "/greengrass/v2",
        "templateParameters": {
          "ThingGroupName": "<existing-thing-group>",
          "ThingName": ""
        }
      }
    },
    "aws.greengrass.Nucleus": {
      "version": ""
    }
  }
}
```
### 4. Running `setup.sh`

This script will:

- Generate a unique device name and update `config.json` with it.
- Install AWS IoT Greengrass V2.
- Configure Fleet Provisioning using the parameters in `config.json`.

```bash
chmod +x setup.sh
./setup.sh <username>
```

Replace `<username>` with your system username.

### 5. Running `uninstall_greengrass.sh` (OPTIONAL)

To uninstall AWS IoT Greengrass and remove the related configuration:

```bash
chmod +x uninstall_greengrass.sh
./uninstall_greengrass.sh <username>
```

Replace `<username>` with your system username.