import json
import boto3
import uuid
from json import loads

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('lambda-testing')

def lambda_handler(event, context):

    body = json.loads(event['body'])

    table.put_item(
        Item={
            'username': body['username'],
            'email': body['email']
        }
    )
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps('Lambda Success!')
    }
    
#test in lambda using this as body
"""
{
  "body": "{\"username\": \"testuser\", \"email\": \"test@example.com\"}"
}
"""