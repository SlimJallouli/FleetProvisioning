# Fleet Provisioning for AWS IoT Greengrass

## Overview
This project helps you set up AWS IoT Fleet Provisioning for GreengrassV2 using AWS CloudFormation, claim certificates, and an IoT provisioning template. The provided template.yaml will create the necessary roles, policies, and templates for provisioning.

## Prerequisites
- **[STM32MP1DK](https://www.st.com/en/evaluation-tools/stm32mp135f-dk.html)**: The device must be set up and [accessible over the network](https://wiki.st.com/stm32mpu/wiki/How_to_setup_a_WLAN_connection).
- **[X-LINUX-AWS](https://wiki.st.com/stm32mpu/wiki/X-LINUX-AWS_Starter_package)**: Ensure that X-LINUX-AWS is installed on the STM32MP1DK.
- **AWS Account**: Access to an AWS account with permissions to manage IAM, IoT, Greengrass, and create Cloudformation Stacks.
- [**AWS CLI**](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html): Ensure the AWS CLI is installed and [configured](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html) on your local machine.
- [**Git Bash**](https://git-scm.com/downloads): Required for windows users as it provides a Unix-like shell that ensures compatibility with the Linux-style commands used in the scripts.
- **SSH Access**: Ensure you can SSH into the STM32MP135 DK.

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

5. **IotConfig_Cleanup.sh**
    - Cleanup that will delete an IoT Thing, its attached certificates and policies, its Thing Group, and its Greengrass V2 core device.

## Steps

### 1. Clone this Repository

On a PC with AWS CLI installed clone this repository:

```bash
git clone https://github.com/stm32-hotspot/FleetProvisioning
cd FleetProvisioning

```

### 2. Create the CloudFormation Stack
Use AWS CLI and the AWS Account with the required privileges to create the CloudFormation Stack

```bash
aws cloudformation create-stack --stack-name GGWorkshopFleetProvisioning --template-body file://template.yaml --capabilities CAPABILITY_NAMED_IAM
```

Wait a few minutes for the resources to be created. You can check the status from the CloudFormation console or with this command:

```bash
aws cloudformation describe-stacks --stack-name GGWorkshopFleetProvisioning
```

Once the stack status is CREATE_COMPLETE, you can proceed to the next section.

### 3. Generate Claim Certificates
Claim certificates are X.509 certificates that allow devices to register as AWS IoT things and retrieve a unique X.509 device certificate for regular operations. After creating a claim certificate, attach an AWS IoT policy that permits devices to create unique device certificates and provision them using a fleet provisioning template.

#### a) Create and save a certificate and private key for provisioning
Navigate into the claim-certs folder

```bash
cd ./claim-certs
```

Run the following command to create and save a certificate and private key:

```bash
aws iot create-keys-and-certificate \
  --certificate-pem-outfile "claim-certs/claim.pem.crt" \
  --public-key-outfile "claim-certs/claim.public.pem.key" \
  --private-key-outfile "claim-certs/claim.private.pem.key" \
  --set-as-active \
  --query 'certificateArn' \
  --output text
```

Take note of the certificate ARN because it will be needed in the next step.

#### b) Attach the IoT Policy to the Provisioning Claim Certificate
Attach the IoT policy created with CloudFormation (GGWorkshopProvisioningClaimPolicy) to the claim certificate:

```bash
aws iot attach-policy --policy-name <GGWorkshopProvisioningClaimPolicy> --target <certificateArn>
```

Replace <certificateArn> with the ARN from the previous step.


### 4. Collect AWS Data and Credential Endoints

Note the output of the following commands as it will be needed for the next step

```bash
aws iot describe-endpoint --endpoint-type iot:CredentialProvider
```
```bash
aws iot describe-endpoint --endpoint-type iot:Data-ATS
```

### 5. Update the Config

Update the following Configuration parameters:
 - awsRegion: Select the nearest AWS Region to you that supports GreengrassV2
 - iotCredentialEndpoint: Use the credential endoint collected in the previous step
 - iotDataEndpoint: Use the data endpoint collected in the previous step
 - iotRoleAlias: Use the Rolea Alias specified in the CloudFormation template.yaml file
 - provisioningTemplate: Use the Provisioning Template name specified in the CloudFormation template.yaml file
 - ThingGroupName: Select the name of an existing thing group. If you dont have one use the following command
 
    ```aws iot create-thing-group --thing-group-name <THING_GROUP_NAME>```

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
```
NOTE: "ThingName" and "version" will be be automatically populated during setup.sh script exectuion. 
```
### 6. Copy Entire Reporository to STM32MP135-DK
These scripts will be run on the STM32MP1 so replace <Board.IP.ADDRESS> with the IP address of your discovery kit and copy the repository over using the following comand

```bash
scp ./* root@<Board.IP.ADDRESS>:~
```

### 7. SSH to the STM32MP135-DK

```bash
ssh root@ <Board.IP.ADDRESS>
```

### 8. Running `setup.sh`

This script will:

- Generate a unique device name and update `config.json` with it.
- Update the Greengrass Nucleus Version
- Install AWS IoT Greengrass V2.
- Configure Fleet Provisioning using the parameters in `config.json`.

```bash
cd ~
chmod +x setup.sh
./setup.sh $USER
```

Replace `<username>` with your system username.

### 9. (OPTIONAL) Running `uninstall_greengrass.sh`

To uninstall AWS IoT Greengrass and remove the related configuration:

```bash
chmod +x uninstall_greengrass.sh
./uninstall_greengrass.sh <username>
```

Replace `<username>` with your system username.