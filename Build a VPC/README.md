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
    It is important to note that the number after the slash in the CIDR block has to be larger than what we had for the VPC.
   -


6. 
