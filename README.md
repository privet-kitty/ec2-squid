# ec2-squid

Start up a proxy server ([squid](https://github.com/squid-cache/squid)) on AWS EC2.

## Usage

### Initialize

```bash
ssh-keygen -t rsa -f squid_key -N ""  # or ssh-keygen -t rsa -f squid_key -N '""' in PowerShell
terraform init
```

### Deploy

You'll need to prepare your AWS profile for deploy. You may want to use aws-vault and add `aws-vault exec <profile> --` as a prefix of the following commands.

```bash
terraform plan
terraform apply
```

### Use

- The public IP and DNS of the proxy server are displayed after deploy. The port number is 3128.
- Logs on start-up are stored at `/var/log/cloud-init-output.log` in the instance.

### Destroy

```bash
terraform destroy
```
