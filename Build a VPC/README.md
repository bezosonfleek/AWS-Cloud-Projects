Aimed at improving networking knowledge.


<img width="507" height="421" alt="architecture-diagram" src="https://github.com/user-attachments/assets/1bf78de0-fc45-4b8c-a59e-05cf101c5fa7" />

1. Create a VPC
   -Navigate to VPC, and select create VPC. Give a name and specify CIDR (I went with 10.0.0.0/16 - it offers 65,536 addresses) - Formula: 2^(32-n); n in my case n is 24.
2. Create Subnets
   -Create new subnet with your VPC ID (Name of your VPC), edit subnet settings and enable auto-assign IPv4 address - to ensure instances get a public address instantly.
3. Create an Internet Gateway
   Internet gateways allow your VPC to connect to the internet.
   -Create a gateway and name, then attach to your VPC. 
4. Creating a different VPC using CloudShell
   -aws ec2 create-vpc --cidr-block 10.0.0.0/24 --query Vpc.VpcId --output text
   -aws ec2 create-tags --resources=VPC-ID --tags Key=Name,Value="Name-of-2nd-VPC"
   -aws ec2 create-subnet --vpc-id VPC-ID --cidr-block 10.0.0.0/25
    It is important to note that the number after the slash in the CIDR block has to be larger than what we had for the VPC CIDR block.
   -aws ec2 create-internet-gateway
   -aws ec2 attach-internet-gateway --vpc-id VPC-ID --internet-gateway-id IG-ID

   A connection to your internet gateway should be visible in the Resource Map. 

VPC Traffic Flow & Security

<img width="772" height="423" alt="vpc-traffic-flow security" src="https://github.com/user-attachments/assets/8a863508-36b8-4982-92c0-4a8d13ed71f2" />

1. Create a route table
   -A route table is created for the VPC you created, you just need to remane it. Add destination 0.0.0.0/0 and selecct your internet gateway. Associate your route table with Public 1 subnet. The subnet is now public.
2. Create a security group
  -Create a new security group and select your VPC, add an inbound rule of HTTP from anywhere. Outbound traffic is allowed by default so we do not set this for now.
3. Create a Network ACL
  -Create and name acl, add associated VPC. Add inbound rule to allow all traffic, do the same for outbound. Add subnet association to your acl (Public 1 subnet).
   Process flow: User -> Internet gateway -> VPC -> Route table -> Network ACL -> Public Subnet -> Security Group -> EC2 Instance -> Data sent.
5. Track VPC resources
   -Create VPCs in different regions using CloudShell
    aws ec2 create-vpc --cidr-block 10.0.0.0/24 --query "Vpc.VpcId" --output text --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=new-region-VPC}]' --region REGION-CODE
   -Create gateway: aws ec2 create-internet-gateway --query "InternetGateway.InternetGatewayId" --output text --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value="new-region-IG"}]' --region REGION-CODE
   -Set up security group: aws ec2 create-security-group --query "GroupId" --output text  --description "New SG created to test creating an SG in another Region." --group-name new-region-sg --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value="new-region-sg"}]' --region REGION-CODE
   -Head to the AWS Global View (important for managing multi-region deployments) - you can see all resources
   -Delete resources:
   aws ec2 delete-vpc --vpc-id VPC-ID
   aws ec2 delete-security-group --group-id SG-ID
   aws ec2 delete-internet-gateway --internet-gateway-id IG-ID 



