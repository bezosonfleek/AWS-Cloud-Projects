# Serverless Web Application Architecture
*A highly available, cost-optimized solution for hosting static sites with dynamic backend processing.*

---

## Architecture Diagram

![System Architecture](cloudcraft.png)

This diagram illustrates a decoupled, serverless architecture that leverages AWS edge locations for content delivery and regional services for application logic and persistence. It provides a blueprint for a secure, scalable, and pay-as-you-go web application, such as a static site with a dynamic contact form or waitlist.

---

## Component Breakdown

### 1. The Global Edge Layer (External)

* **[User]:** Represents the end-client browsing the internet.
* **[CloudFront]:** Amazon’s Content Delivery Network (CDN). It serves the static website content from edge locations globally, reducing latency. It is positioned outside the specific `us-east-1` region to emphasize its global distribution.

### 2. The Regional Infrastructure (`us-east-1`)

* **[S3 Bucket]:** Amazon Simple Storage Service used for hosting the **Static Site**. It acts as the "Origin" for CloudFront. Access is secured using an Origin Access Control (OAC) policy, ensuring the bucket is only accessible through CloudFront.
* **[API Gateway]:** Provides a secure, scalable entry point for all dynamic backend requests. It acts as the interface for the frontend to communicate with the application logic.
* **[AWS Lambda]:** The "serverless compute" layer. This function is triggered by API Gateway, processes the incoming request (e.g., form validation), and executes business logic. It runs only when called, optimizing costs.
* **[DynamoDB]:** A fully managed NoSQL database service that provides single-digit millisecond latency at any scale. Used here for persistent storage of user-submitted data (like waitlist entries).

---

## Deployment and Security Workflow

### Static Content Delivery (Read Path)
1.  **User** requests the website URL.
2.  Request hits a global **CloudFront** edge location.
3.  CloudFront fetches the content from the private **S3 Bucket** (if not cached) and delivers it to the User.

### Dynamic Interaction (Write Path)
1.  **User** submits a form on the static site.
2.  Frontend sends an HTTPS request to the **API Gateway**.
3.  API Gateway triggers the **AWS Lambda** function, passing the form data.
4.  Lambda validates the data and writes it to the **DynamoDB** table.
5.  A success or error response flows back from DynamoDB → Lambda → API Gateway → User.

---

## Author
* **Project Mtaani / IT professional specializing in Cloud Native architecture and automation.**