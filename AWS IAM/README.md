 AWS Identity and Access Management (IAM) 

 -In this mini-project, I'll launch an EC2 instance and control who has access to it by use if IAM policies and user groups
  This is aimed at improving knowledge of Cloud Security. 

 Diagrammatic representation: 
<img width="770" height="595" alt="architecture-diagram" src="https://github.com/user-attachments/assets/70451ff6-eb68-407b-aded-7a1d1d8caacd" />

1. Launch EC2 instances
   - Name prod-name, add tag Key: Env, Value: production. Choose Free Tier eligible options since it is a test project. Proceed without key pair.
   - Name dev-name,add tag Key: Env, Value: production; second EC2 instance.
2. Create an IAM policy
    We are using the IAM policy to give permission to the development instance only.
   - In IAM select policy and create. Paste the contents of policy.json there, this allows for access to the dev environment. Name the policy and create.
3. Create an Accout Alias
   Allows for a friendly ID for other users onboarded to use
   -On the right side of IAM dashboard, create account alias with name
4. Create IAM Users & User Groups
   -Still in IAM, create a user group and name it. Ensure to attach the policy you created.
   -Create a user, add them to the group.
5. Test access
   -Use the link to login as IAM user.
   -Once logged in, ensure you are in the same region as the one you created the instances.
   -Try to stop the production & development instances and notice the difference.

Additional steps

6. IAM Policy Simulator
   -Used to validate policies without affecting resources
   
