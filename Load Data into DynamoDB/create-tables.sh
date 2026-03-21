
aws dynamodb create-table
--table-name ContentCatalog
--attribute-definitions
AttributeName=Id,AttributeType=N
--key-schema
AttributeName=Id,KeyType=HASH
--provisioned-throughput
ReadCapacityUnits=1,WriteCapacityUnits=1
--query "TableDescription.TableStatus" 
aws dynamodb create-table
--table-name Forum
--attribute-definitions
AttributeName=Name,AttributeType=S
--key-schema
AttributeName=Name,KeyType=HASH
--provisioned-throughput
ReadCapacityUnits=1,WriteCapacityUnits=1
--query "TableDescription.TableStatus" 
aws dynamodb create-table
--table-name Post
--attribute-definitions
AttributeName=ForumName,AttributeType=S
AttributeName=Subject,AttributeType=S
--key-schema
AttributeName=ForumName,KeyType=HASH
AttributeName=Subject,KeyType=RANGE
--provisioned-throughput
ReadCapacityUnits=1,WriteCapacityUnits=1
--query "TableDescription.TableStatus" 
aws dynamodb create-table
--table-name Comment
--attribute-definitions
AttributeName=Id,AttributeType=S
AttributeName=CommentDateTime,AttributeType=S
--key-schema
AttributeName=Id,KeyType=HASH
AttributeName=CommentDateTime,KeyType=RANGE
--provisioned-throughput
ReadCapacityUnits=1,WriteCapacityUnits=1
--query "TableDescription.TableStatus"
