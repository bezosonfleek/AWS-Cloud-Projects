![System Architecture](cloudcraft.png)

create s3 bucket
-block public access
create cloudfront distribution
-root folder: /index.html
-choose the s3 bucket as origin
-ensure policy is updated in s3
-add error page to ensure good SPA routing

Serverless Web Application Architecture
A highly available, cost-optimized solution for hosting static sites with dynamic backend processing.

Deployment Steps
1. Storage & Delivery
Amazon S3: Created a private bucket with Block Public Access enabled to host static assets.

CloudFront: Configured a distribution using the S3 bucket as the Origin to ensure global low-latency delivery.

Security: Implemented Origin Access Control (OAC) to ensure the S3 bucket is only accessible via CloudFront.

2. Backend Logic
API Gateway: Set up a REST endpoint to handle frontend form submissions.

AWS Lambda: A Python-based function triggered by the API to process data.

DynamoDB: A NoSQL table used for persistent storage of user waitlist data.