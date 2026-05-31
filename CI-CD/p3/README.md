# CI/CD Static Site — GitHub Actions + AWS S3 + CloudFront

A collection of static HTML pages deployed automatically to AWS S3 via GitHub Actions, served globally through CloudFront with OAC (Origin Access Control).

---

## Live URLs

| Resource | URL |
|---|---|
| CloudFront | `https://d8y6oxlxn4izn.cloudfront.net` |
| S3 (direct) | `http://review-cicd.s3-website-us-east-1.amazonaws.com` |

---

## Project Structure

```
AWS-Cloud-Projects/
├── .github/
│   └── workflows/
│       └── deploy.yml        ← GitHub Actions pipeline (repo root)
│
└── CI-CD/
    └── p3/
        ├── index.html        ← CI/CD pipeline success page
        ├── error.html        ← 404 / error page
        ├── k8s.html          ← Kubernetes stack page
        ├── aws.html          ← AWS stack page
        ├── docker.html       ← Docker stack page
        ├── terraform.html    ← Terraform stack page
        └── .htmlhintrc       ← HTML lint config
```

> **Important:** `deploy.yml` must live at the repo root under `.github/workflows/` — not inside a subfolder. GitHub Actions only reads workflows from the root level.

---

## Pages

| File | Description | Theme colour |
|---|---|---|
| `index.html` | Pipeline success — nginx-style confirmation | Green |
| `error.html` | 404 error with fake failed log output | Red |
| `k8s.html` | Kubernetes tech stack showcase | Blue `#3b82f6` |
| `aws.html` | AWS tech stack showcase | Orange `#ff9900` |
| `docker.html` | Docker tech stack showcase | Cyan `#2496ed` |
| `terraform.html` | Terraform tech stack showcase | Purple `#7b42f6` |

All pages share the same dark terminal design system:
- **Background:** `#0f1117`
- **Surface:** `#1a1f2e`
- **Font:** DM Mono (Google Fonts)

---

## Pipeline

```
Push to CI-CD/p3/**
        ↓
GitHub Actions (ubuntu-latest)
        ↓
Checkout → Lint HTML → Configure AWS → Sync to S3 → Invalidate CloudFront
        ↓
Live on CloudFront
```

The `paths` filter means the pipeline **only triggers** when files inside `CI-CD/p3/` change. Pushes to other folders are ignored.

---

## Setup — Full Guide

### 1. Clone the repo

```bash
git clone https://github.com/bezosonfleek/AWS-Cloud-Projects.git
cd AWS-Cloud-Projects
```

### 2. Create the S3 bucket

```bash
aws s3 mb s3://YOUR-BUCKET-NAME --region us-east-1
```

Enable static website hosting:
```bash
aws s3 website s3://YOUR-BUCKET-NAME \
  --index-document index.html \
  --error-document error.html
```

> Keep **Block all public access ON** — the bucket will be private, only accessible through CloudFront via OAC.

### 3. Create a CloudFront distribution

- Go to CloudFront → Create distribution
- **Origin domain** — pick the S3 REST endpoint (not the website endpoint):
  ```
  YOUR-BUCKET-NAME.s3.us-east-1.amazonaws.com
  ```
  > Do NOT use the `s3-website` endpoint — OAC won't work with it
- **Origin access** → select **Origin access control settings (recommended)**
- Click **Create new OAC** → accept defaults → Create
- **Default root object** → `index.html`
- Create distribution
- **Copy the generated bucket policy** from the banner and paste it into S3 → Permissions → Bucket policy

### 4. Set up CloudFront custom error pages

CloudFront → your distribution → **Error pages** tab → Create custom error response:

| HTTP error code | Response page path | HTTP response code |
|---|---|---|
| 403 | `/error.html` | 404 |
| 404 | `/error.html` | 404 |

> With OAC + private bucket, missing files return 403 (not 404) from S3 — map both to your error page.

### 5. Create the IAM deploy user

Go to IAM → Users → Create user → name it `github-deploy`.

After creation, open the user → Permissions → Add permissions → **Create inline policy** → JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3DeployAccess",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME",
        "arn:aws:s3:::YOUR-BUCKET-NAME/*"
      ]
    },
    {
      "Sid": "CloudFrontInvalidation",
      "Effect": "Allow",
      "Action": ["cloudfront:CreateInvalidation"],
      "Resource": "*"
    }
  ]
}
```

> Use inline policy, not managed policies — least privilege means only granting what the pipeline actually needs.

Then go to Security credentials → **Create access key** → save both values. You won't see the secret again.

### 6. Add GitHub Secrets

Repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM access key ID |
| `AWS_SECRET_ACCESS_KEY` | IAM secret access key |
| `AWS_REGION` | `us-east-1` |
| `S3_BUCKET_NAME` | Your bucket name |
| `CLOUDFRONT_DISTRIBUTION_ID` | Distribution ID only — e.g. `E11Y4X6737RKRU` (not the URL) |

> **Common mistake:** `CLOUDFRONT_DISTRIBUTION_ID` must be the ID (e.g. `E11Y4X6737RKRU`), not the domain URL (`d8y6oxlxn4izn.cloudfront.net`). Using the URL causes exit code 254.

### 7. Add the workflow file

Create `.github/workflows/deploy.yml` at the **repo root**:

```yaml
name: Deploy to S3

on:
  push:
    branches:
      - main
    paths:
      - "CI-CD/p3/**"

jobs:
  deploy:
    name: Build & Deploy
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Lint HTML
        run: |
          npm install -g htmlhint --silent
          htmlhint "CI-CD/p3/**/*.html" || true

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region:            ${{ secrets.AWS_REGION }}

      - name: Deploy to S3
        run: |
          aws s3 sync ./CI-CD/p3 s3://${{ secrets.S3_BUCKET_NAME }} \
            --exclude ".git/*" \
            --exclude ".github/*" \
            --delete \
            --cache-control "max-age=86400"

      - name: Invalidate CloudFront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"
```

### 8. Push and verify

```bash
git add .
git commit -m "initial deploy"
git push origin main
```

Go to repo → **Actions tab** → watch the pipeline run. All steps should go green.

---

## Common Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `No event triggers defined in on` | `deploy.yml` pushed empty | Add the full `on:` block and repush |
| Pipeline doesn't trigger | `paths` filter — no matching files changed | Push a real change inside `CI-CD/p3/` |
| `Exit code 254` on CloudFront step | Wrong distribution ID or missing IAM permission | Use the ID not the URL; add `cloudfront:CreateInvalidation` to IAM policy |
| `403 Forbidden` on CloudFront URL | OAC not configured or wrong S3 origin endpoint | Use REST endpoint, set up OAC, copy generated policy to S3 |
| XML `AccessDenied` response | Default root object not set | CloudFront → General → set `index.html` as default root object |
| Error page not showing | Custom error responses not configured | CloudFront → Error pages → map 403 and 404 to `/error.html` |
| S3 origin type shows `S3 static website` | Using website endpoint instead of REST endpoint | Change origin to `bucket.s3.region.amazonaws.com` |

---

## Key Concepts

**Why REST endpoint over website endpoint for OAC**
OAC only works with the S3 REST endpoint (`bucket.s3.region.amazonaws.com`). The website endpoint (`bucket.s3-website-region.amazonaws.com`) is treated as a custom HTTP origin — OAC options don't appear and the generated bucket policy is never offered.

**Why both 403 and 404 need custom error responses**
With a private S3 bucket behind OAC, when a requested file doesn't exist S3 returns 403 (not 404) to CloudFront — because it can't confirm whether the file exists or is just inaccessible. Map both to your error page.

**Why the paths filter matters**
Without it, every push to any folder in the repo triggers a deploy. With it, only changes to `CI-CD/p3/` fire the pipeline — other project folders are unaffected.

**Why inline policy over managed policy**
AWS managed CloudFront policies (`CloudFrontFullAccess`) grant way more than needed. A deploy user should only have `cloudfront:CreateInvalidation` — nothing else. No managed policy exists for just that action, so inline is the only correct approach.

---

## Author

**bezosonfleek** (Geoffrey Sakora) · [github.com/bezosonfleek](https://github.com/bezosonfleek/AWS-Cloud-Projects)