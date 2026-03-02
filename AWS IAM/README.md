 AWS Identity and Access Management (IAM) 

 -In this mini-project, I'll launch an EC2 instance and control who has access to it by use if IAM policies and user groups
  This is aimed at improving knowledge of Cloud Security. 

 Diagrammatic representation: 
<img width="770" height="595" alt="architecture-diagram" src="https://github.com/user-attachments/assets/70451ff6-eb68-407b-aded-7a1d1d8caacd" />

1. Launch EC2 instances
   - Name prod-name, add tag Key: Env, Value: production. Choose Free Tier eligible options since it is a test project. Proceed without key pair.
   - Name dev-name; second EC2 instance.
2. Create an IAM policy
   We are using the IAM policy to give permission to the development instance only.
   -
3. 
