
# Fleet Provisioning for AWS IoT Greengrass

## Overview
This project provides a setup for AWS IoT Fleet Provisioning with GreengrassV2 using AWS CloudFormation, claim certificates, and an IoT provisioning template. This enables scalable, secure, and automated provisioning of IoT devices, allowing them to self-register with minimal intervention and maintain secure communication through AWS IoT.

## Prerequisites
- **[STM32MP1DK](https://www.st.com/en/evaluation-tools/stm32mp135f-dk.html)**: The device must be set up and [accessible over the network](https://wiki.st.com/stm32mpu/wiki/How_to_setup_a_WLAN_connection).
- **[X-LINUX-AWS](https://wiki.st.com/stm32mpu/wiki/X-LINUX-AWS_Starter_package)**: Ensure that X-LINUX-AWS is installed on the STM32MP1DK.
- **AWS Account**: Access to an AWS account with permissions to manage IAM, IoT, Greengrass, and create CloudFormation Stacks.
- **[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)**: Install and [configure](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html) the AWS CLI on your local machine.
- **[Git Bash](https://git-scm.com/downloads)**: Required for Windows users, as it provides a Unix-like shell compatible with the scripts used.
- **SSH Access**: Ensure you can SSH into the STM32MP135 DK.

## Files

1. **setup.sh**
   - Configures AWS IoT Greengrass V2 with Fleet Provisioning.
   - Generates a unique device name using the hostname and machine ID.
   - Downloads and installs necessary dependencies.
   - Copies claim certificates, installs Greengrass, and configures the system service.

2. **uninstall_greengrass.sh**
   - Stops the Greengrass service.
   - Removes Greengrass installation and configuration files from the system.

3. **config.json**
   - Configuration file for AWS IoT Greengrass and Fleet Provisioning.
   - Sets parameters such as AWS region, claim certificate paths, IoT credential and data endpoints, role alias, and provisioning template.

4. **template.yaml**
   - CloudFormation template for configuring Greengrass Fleet Provisioning resources.

5. **IotConfig_Cleanup.sh**
   - Cleans up IoT resources by deleting an IoT Thing, its certificates, policies, Thing Group, and Greengrass V2 core device.

---

## Setup Steps

### 1. Clone this Repository
On a PC with AWS CLI installed, clone this repository:

```bash
git clone https://github.com/stm32-hotspot/FleetProvisioning
cd FleetProvisioning
```

### 2. Create the CloudFormation Stack
Use AWS CLI with the required privileges to create the CloudFormation Stack:

```bash
aws cloudformation create-stack --stack-name GGWorkshopFleetProvisioning --template-body file://template.yaml --capabilities CAPABILITY_NAMED_IAM
```

Wait for a few minutes until the resources are created. Check the status from the CloudFormation console or use the command:

```bash
aws cloudformation describe-stacks --stack-name GGWorkshopFleetProvisioning
```

Once the stack status is `CREATE_COMPLETE`, you can proceed.

### 3. Generate Claim Certificates
Claim certificates allow devices to register as AWS IoT Things and retrieve unique device certificates.

#### a) Create and Save a Certificate and Private Key for Provisioning

Run the following command to create and save a certificate and private key:

```bash
aws iot create-keys-and-certificate   --certificate-pem-outfile "claim-certs/claim.pem.crt"   --public-key-outfile "claim-certs/claim.public.pem.key"   --private-key-outfile "claim-certs/claim.private.pem.key"   --set-as-active   --query 'certificateArn'   --output text
```

Take note of the `<certificateArn>` output, as it will be needed in the next step.

#### b) Attach the IoT Policy to the Provisioning Claim Certificate
Attach the IoT policy created by CloudFormation (GGWorkshopProvisioningClaimPolicy) to the claim certificate:

```bash
aws iot attach-policy --policy-name GGWorkshopProvisioningClaimPolicy --target <certificateArn>
```

Replace `<certificateArn>` with the ARN obtained from the previous step.

### 4. Collect AWS Data and Credential Endpoints
Note the outputs of the following commands, as they will be needed in the next step.

**Credential Endpoint:**
```bash
aws iot describe-endpoint --endpoint-type iot:CredentialProvider
```

**Data Endpoint:**
```bash
aws iot describe-endpoint --endpoint-type iot:Data-ATS
```

### 5. Update the Config

Edit the `config.json` file with the following parameters:
   - `awsRegion`: Select a Greengrass-supported AWS Region nearest to you.
   - `iotCredentialEndpoint`: Use the credential endpoint obtained in the previous step.
   - `iotDataEndpoint`: Use the data endpoint obtained in the previous step.
   - `iotRoleAlias`: Use the Role Alias specified in the CloudFormation `template.yaml`.
   - `provisioningTemplate`: Use the Provisioning Template name specified in `template.yaml`.
   - `ThingGroupName`: Specify the name of an existing Thing Group. If you don’t have one, create it with:

      ```bash
      aws iot create-thing-group --thing-group-name <THING_GROUP_NAME>
      ```

Example configuration:

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

> **Note:** `ThingName` and `version` will be automatically populated during the execution of `setup.sh`.

### 6. Copy Entire Repository to STM32MP135-DK
Replace `<Board.IP.ADDRESS>` with your board's IP address and copy the repository:

```bash
scp -r ./* root@<Board.IP.ADDRESS>:~
```

### 7. SSH to the STM32MP135-DK

```bash
ssh root@<Board.IP.ADDRESS>
```

### 8. Running `setup.sh`
The `setup.sh` script will:
   - Generate a unique device name and update `config.json` with it.
   - Update the Greengrass Nucleus version.
   - Install AWS IoT Greengrass V2.
   - Configure Fleet Provisioning using `config.json`.

Run:

```bash
cd ~
chmod +x setup.sh
./setup.sh $USER
```

### 9. Verify Greengrass Core Device Status
To confirm that your device has been successfully set up and registered as a Greengrass core device, use:

```bash
aws greengrassv2 list-core-devices --status HEALTHY
```

### 10. (Optional) Running `uninstall_greengrass.sh`
To remove AWS IoT Greengrass and its configuration files from your device:

```bash
chmod +x uninstall_greengrass.sh
./uninstall_greengrass.sh $USER
```

---

### Troubleshooting
If you encounter issues, check the following:
   - **Network Connectivity**: Ensure the device can access AWS IoT endpoints.
   - **IAM Permissions**: Verify your AWS account has the required permissions for IoT, Greengrass, and CloudFormation.
   - **Certificate and Policy Issues**: Ensure the claim certificate and attached policies are correctly set up.

---

This README should help you set up Fleet Provisioning with AWS IoT Greengrass on your STM32MP1 device efficiently. Let me know if you'd like any further customization!
