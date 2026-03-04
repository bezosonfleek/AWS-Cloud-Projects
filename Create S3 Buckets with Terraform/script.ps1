New-Item -Path "$env:USERPROFILE\Desktop\s3_terraform" -ItemType Directory

Set-Location "$env:USERPROFILE\Desktop\s3_terraform"

Get-Location

New-Item -Path "main.tf" -ItemType File
