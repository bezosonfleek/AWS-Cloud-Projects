# CI/CD Static Site — AWS S3 + GitHub Actions

A collection of static HTML pages deployed automatically to AWS S3 via GitHub Actions. Includes a CI/CD pipeline success page, error page, and individual tech stack showcase pages.

---

## Project Structure

```
CI-CD/p3/
├── index.html          # CI/CD pipeline success page
├── error.html          # 404 / error page
├── k8s.html            # Kubernetes stack page
├── aws.html            # AWS stack page
├── docker.html         # Docker stack page
├── terraform.html      # Terraform stack page
└── .htmlhintrc         # HTML lint rules

.github/
└── workflows/
    └── deploy.yml      # GitHub Actions pipeline
```

---

## Pages

| File | Description | Accent Colour |
|---|---|---|
| `index.html` | Pipeline success — nginx-style confirmation page | Green |
| `error.html` | 404 error page with fake failed log output | Red |
| `k8s.html` | Kubernetes tech stack showcase | Blue |
| `aws.html` | AWS tech stack showcase | Orange |
| `docker.html` | Docker tech stack showcase | Cyan |
| `terraform.html` | Terraform tech stack showcase | Purple |

---

## Tech Stack

- **Frontend** - Vanilla HTML/CSS, DM Mono font (Google Fonts)
- **Hosting** - AWS S3 (static website hosting)
- **CDN** - AWS CloudFront (optional but recommended)
- **CI/CD** - GitHub Actions
- **Linting** - htmlhint

---

## Prerequisites

- AWS account with S3 access
- GitHub repository
- AWS CLI (for manual setup steps)

---

## Setup — Step by Step

### 1. Clone or fork the repo

```bash
git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git
cd YOUR-REPO
```

### 2. Create an S3 bucket

```bash
aws s3 mb s3://YOUR-BUCKET-NAME --region YOUR-REGION
```

Enable static website hosting:

```bash
aws s3 website s3://YOUR-BUCKET-NAME \
  --index-document index.html \
  --error-document error.html
```

Attach a public bucket policy — go to S3 → your bucket → Permissions → Bucket policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
  }]
}
```

Make sure **Block all public access** is turned off.

### 3. Create an IAM deploy user

Go to IAM → Users → Create user → name it `github-deploy`.

Skip managed policies. After creation, open the user → Permissions → Add permissions → Create inline policy → JSON tab:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
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
  }]
}
```

Then go to Security credentials → Create access key → save both values. **You won't see the secret again.**

If using CloudFront, add this to the IAM policy:

```json
{
  "Effect": "Allow",
  "Action": ["cloudfront:CreateInvalidation"],
  "Resource": "arn:aws:cloudfront::YOUR-ACCOUNT-ID:distribution/*"
}
```

### 4. Add GitHub Secrets

Go to your repo → Settings → Secrets and variables → Actions → New repository secret.

Add these four:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM access key ID |
| `AWS_SECRET_ACCESS_KEY` | IAM secret access key |
| `AWS_REGION` | e.g. `af-south-1` |
| `S3_BUCKET_NAME` | Your bucket name |

If using CloudFront, add a fifth:

| Secret | Value |
|---|---|
| `CLOUDFRONT_DISTRIBUTION_ID` | Your distribution ID |

### 5. Add the workflow file

Create `.github/workflows/deploy.yml` at the **root of the repo**:

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
        if: ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID != '' }}
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"
```

> **Note:** The `paths` filter means the pipeline only triggers when files inside `CI-CD/p3/` change. Adjust the path to match your folder structure.

### 6. Push and verify

```bash
git add .
git commit -m "initial deploy"
git push origin main
```

Go to repo → Actions tab → watch the pipeline run. Green checkmark = deployed.

Your site will be live at:
```
http://YOUR-BUCKET-NAME.s3-website-YOUR-REGION.amazonaws.com
```

---

## Errors I faced

| Error | Cause | Fix |
|---|---|---|
| `No event triggers defined in on` | `deploy.yml` was pushed empty | Add the full `on:` block and repush |
| `Access Denied` on S3 sync | IAM policy missing or wrong bucket name | Check inline policy ARNs match bucket name exactly |
| Pipeline doesn't trigger | `paths` filter — no files changed in that folder | Push a real file change inside `CI-CD/p3/` |
| CloudFront shows old content | Cache not invalidated | Add CloudFront invalidation step or manually invalidate `/*` |
| `403` on custom domain | Domain not added to CloudFront alternate names | Add domain in CloudFront → Settings → Alternate domain names |

---

## Customisation

**Change the folder path** — update `paths` and `aws s3 sync` in `deploy.yml` to match your structure.

**Add CloudFront** — point a CloudFront distribution at your S3 website endpoint, attach an ACM certificate from `us-east-1`, and add the invalidation step to the workflow.

**Custom domain** — add a CNAME at your DNS provider pointing to the CloudFront distribution URL, then add the domain to CloudFront's alternate domain names.

**Update stack pages** — each `k8s.html`, `aws.html`, `docker.html`, `terraform.html` is self-contained. Edit the tags, terminal commands and description to match your actual experience.

---

## Theme

All pages share the same design system:

- **Background:** `#0f1117`
- **Surface:** `#1a1f2e`
- **Border:** `#2d3748`
- **Font:** DM Mono (Google Fonts)
- **Accent colours:** green (CI/CD), red (error), blue (K8s), orange (AWS), cyan (Docker), purple (Terraform)

---

## AUTHOR

**bezosonfleek** · [github.com/bezosonfleek](https://github.com/bezosonfleek)
**Site:** · [https://d8y6oxlxn4izn.cloudfront.net/]https://d8y6oxlxn4izn.cloudfront.net/)