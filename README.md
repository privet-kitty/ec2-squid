# ec2-squid

Start up a proxy server ([squid](https://github.com/squid-cache/squid)) on AWS EC2.

## Usage

### Initialize

```bash
ssh-keygen -t rsa -f squid_key -N ""  # or ssh-keygen -t rsa -f squid_key -N '""' in PowerShell
terraform init
```

You may want to put terraform variables to `terraform.tfvars` priot to init. The currently used variable are as follows:

```
aws_region = <region name>
```

### Deploy

You'll need to prepare your AWS profile for deploy. You may want to use aws-vault and add `aws-vault exec <profile> --` as a prefix of the following commands.

```bash
terraform plan
terraform apply
```

### Use

- The public IP and DNS of the proxy server are displayed after deploy. The port number is 3128.
- SSH login command will be like `ssh -i squid_key ec2-user@<public IP>`.
- Logs on start-up are stored at `/var/log/cloud-init-output.log` in the instance.

### Destroy

```bash
terraform destroy
```
