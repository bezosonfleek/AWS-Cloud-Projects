AWS DynamoDB - NoSQL Database.

Architecture diagram:
<img width="1008" height="542" alt="architecture-diagram" src="https://github.com/user-attachments/assets/4c9f015f-b441-441c-84cf-3f68220b0bf1" />

1. Open DynamoDB using the management console.
   Create table, give it a name and partition key. Change the other settings according to your needs, use the least capacity for a test project: turn of auto-scaling, change provision
   capacity units to 1.
2. Under actions Create Item, populate.
3. Create DynamoDB tables with CloudShell
   Run these commands to create tables:

aws dynamodb create-table \
    --table-name ContentCatalog \
    --attribute-definitions \
        AttributeName=Id,AttributeType=N \
    --key-schema \
        AttributeName=Id,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --query "TableDescription.TableStatus"
aws dynamodb create-table \
    --table-name Forum \
    --attribute-definitions \
        AttributeName=Name,AttributeType=S \
    --key-schema \
        AttributeName=Name,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --query "TableDescription.TableStatus"
aws dynamodb create-table \
    --table-name Post \
    --attribute-definitions \
        AttributeName=ForumName,AttributeType=S \
        AttributeName=Subject,AttributeType=S \
    --key-schema \
        AttributeName=ForumName,KeyType=HASH \
        AttributeName=Subject,KeyType=RANGE \
    --provisioned-throughput \
        ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --query "TableDescription.TableStatus"
aws dynamodb create-table \
    --table-name Comment \
    --attribute-definitions \
        AttributeName=Id,AttributeType=S \
        AttributeName=CommentDateTime,AttributeType=S \
    --key-schema \
        AttributeName=Id,KeyType=HASH \
        AttributeName=CommentDateTime,KeyType=RANGE \
    --provisioned-throughput \
        ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --query "TableDescription.TableStatus"

 Run this script with wait commands to confirm the tables were actually created...

aws dynamodb wait table-exists --table-name ContentCatalog
aws dynamodb wait table-exists --table-name Forum
aws dynamodb wait table-exists --table-name Post
aws dynamodb wait table-exists --table-name Comment

 Head back into your DynamoDB console and select the Tables tab and confirm the created tables.

4. Load data into the Tables
   In CloudShell, download and unzip this file with data:
   curl -O https://storage.googleapis.com/nextwork_course_resources/courses/aws/AWS%20Project%20People%20projects/Project%3A%20Query%20Data%20with%20DynamoDB/nextworksampledata.zip
   unzip nextworksampledata.zip
   cd nextworksampledata

   ls ... cat Forum.json

   Load the data of all four files into DynamoDB using AWS CLI's batch-write-item command:

   aws dynamodb batch-write-item --request-items file://ContentCatalog.json
   aws dynamodb batch-write-item --request-items file://Forum.json
   aws dynamodb batch-write-item --request-items file://Post.json
   aws dynamodb batch-write-item --request-items file://Comment.json

The aws dynamodb batch-write-item command is used to load or insert multiple items into DynamoDB tables!
--request-items tells DynamoDB that the items are currently stored inside a file that it'll need to retrieve from.
file:// then tells DynamoDB that the file is stored locally in the CloudShell environment, with the name FILENAME.json.

💡 How does DynamoDB know which table to store which data?
Each .json file you upload tells DynamoDB which table the items should go to!

5. View and update your loaded data



 

 
