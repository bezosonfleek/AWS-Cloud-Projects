Automating the processes around S3.

Terraform is a tool that helps you build and manage your cloud infrastructure using code. It is done in form of scripts instead of manually.
IaC is the practice of describing your cloud setup in plain text files instead of clicking through a web console. Terraform is an IaC tool.

-Download Terraform
-On Windows; go to advanced system settings to add a system environment variable. 

-Execute the powershell commands in scripts.ps1 to create a working folder, navigate to it, confirm location and create main.tf

-Define main.tf: Copy the code in main.tf to yours.

You can make modifications using the documentation on terraform's site: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

-Run your Terraform configuration

On your local terminal: terraform init, terraform plan

In case of credentials error, use the commands in Powershell: 

- Download AWS CLI installer MSI file: Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"

-Start-Process msiexec.exe -ArgumentList "/i AWSCLIV2.msi" -Wait (Run installer and wait for it to finish)

- Verify download: aws --version

- Configure AWS CLI: aws configure
  It asks for an AWS Access key. Get this from the Management console in IAM. Go into the IAM admin and under the Security credentials sections, create access key

- Head back to the working directory: terraform init, terraform plan

- Launch S3 bucket using Terraform: terraform apply

  Confirm in the management console that an S3 bucket is created. Use 'terraform destroy' to delete the bucket. 

- Upload S3 object with Terraform
