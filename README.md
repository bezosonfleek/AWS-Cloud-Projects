# website-on-s3
Hosting a static website on S3.

1. Create an S3 bucket on AWS, with default settings.
2. Any files can do, I went for the classic html/css combination. Upload the file to your s3 bucket.
3. Allow public access via permissions. (This does not make the bucket public but gives us the chance to do so)
4. Add the bucket policy in permissions, replace the resource with your resource name
5. Enable static hosting in properties; link to the site is then available.
###
6. Open Route53 for Custom DNS...
