# ec2-squid

Start up a proxy server ([squid](https://github.com/squid-cache/squid)) on AWS EC2.

## Usage

### Initialize

```bash
ssh-keygen -t rsa -f squid_key -N ""  # or ssh-keygen -t rsa -f squid_key -N '""' in PowerShell
terraform init
```

### Deploy

You can deploy a proxy server by `terraform apply`. You'll need to prepare your AWS profile for deploy in advance. You may want to use aws-vault and add `aws-vault exec <profile> --` as a prefix of the command.

You can set terraform variables via e.g. `terraform.tfvars` or `-var` option (like `terraform apply -var='aws_region=ap-northeast-1'`). The currently used variables (and their default values) are as follows.

```
aws_region = "ap-northeast-1"
project_code = null  # used as ProjectCode tag
```

Please note that you need the same variables setting also when you __destroy__ the instance. Otherwise some resources may not be deleted.



### Use

- The public IP and DNS of the proxy server are displayed after deploy. The port number is 3128.
- SSH login command will be like `ssh -i squid_key ec2-user@<public IP>`.
- Logs on start-up are stored at `/var/log/cloud-init-output.log` in the instance.

### Destroy

```bash
terraform destroy
```
