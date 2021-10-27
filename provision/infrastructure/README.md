# Infrastructure

Terraform is used to manage the infrastructure. If you don't have that, you'll need to [install it](https://learn.hashicorp.com/tutorials/terraform/install-cli).

You'll need the following environment variables in your shell to run the Terraform plans:

- `CLOUDFLARE_API_TOKEN`
- `DIGITALOCEAN_TOKEN`
- `DOPPLER_TOKEN`

```bash
TERRAFORM_OPTS="-var doppler_token=$DOPPLER_TOKEN"
```

## Deploying

### Previewing Changes

```bash
terraform plan $TERRAFORM_OPTS
```

### Applying Changes

```bash
terraform apply $TERRAFORM_OPTS
```

### Nuke From Orbit

```bash
terraform destroy $TERRAFORM_OPTS
```

## Debugging

To get all values that are output by Terraform run:

```bash
$ terraform output
ip_address = "xxx.xxx.xxx.xxx"
```

SSH is available using the `digital_ocean` key.

```bash
ssh -i ~/.ssh/digital_ocean root@<ip-address>
```
