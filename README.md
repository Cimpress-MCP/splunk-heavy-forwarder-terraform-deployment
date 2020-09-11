# heavy-forwarder-terraform

This deploys a Splunk heavy forwarder (HFW) in AWS along with ancillary infrastructure using [Terraform](https://www.terraform.io/).  It requires an AMI for the HFW.  The AMI can be built with an [accompanying Packer repository](https://github.com/Cimpress-MCP/splunk-heavy-forwarder-packer-ami).

This performs the following steps:

 1. Generates an empty AWS instance profile/role to associate with all resources (this prevents them from having any permissions via metadata endpoints)
 2. Uses the AMI built from the associated Packer repository to deploy a Splunk HFW into a private subnet
 3. Deploys a bastion host/jump box into a public subnet
 4. Allows SSH traffic from the bastion host to the HFW
 5. Deploys an application load balancer to the public subnet
 6. Allows HTTPS traffic from the load balancer to the HFW
 7. Allows HTTPS traffic from the internet to access the load balancer
 8. Allows HEC traffic from the load balancer to the HFW
 9. Allows HEC traffic from the internet to the load balancer
 10. Configures the load balancer to redirect HTTP traffic to HTTPS
 11. Attaches a domain name to the load balancer
 12. Attaches an SSL certificate to the load balancer
 13. Resets the splunk admin password

Once it deploys you should be able to navigate to `your.hfw.domain.example.com` in your browser and login using `admin` for the username and whatever password you set in the Terraform config.

Details for connecting to the machine via SSH are in the [SSH](#SSH) section below.

## Additional Requirements

This repo cannot create all the necessary resources to build the HFW.  You will have to manually create the following resources:

 1. A Route53 hosted DNS Zone
 2. An ACM (aka SSL certificate) for the domain you intend to host the HFW on
 3. A VPC with 2 public subnets
 4. An AWS SSH key
 5. An AMI with the HFW

Again, the AMI can be [built with Packer](https://github.com/Cimpress-MCP/splunk-heavy-forwarder-packer-ami).  This repo assumes that you have first built the AMI with Packer, and so looks for an AMI in your deployment region with a name of `splunk_heavy_forwarder_aws_linux_8.0.5`, which is the AMI name created by the Packer repo.  If you have an AMI with a different name then simply set:

```
ami_name = "[NAME_HERE]"
```

in [terraform.tfvars](terraform.tfvars)

The AMI does need to be in the same region where you are deploying this infrastructure.

## Running Terraform

To run Terraform you will need to collect the following pieces of information, most of which come out of AWS:

 1. A name for your deployment
 2. The region you wish to deploy to
 3. The ID of the VPC you want to deploy to (e.g. `vpc-xxxxxxxxxxxxxxxxx`)
 4. The ID of the public subnet where the HFW/bastion host will be deployed (e.g. `subnet-xxxxxxxxxxxxxxxxx`)
 5. The ID of another public subnet - application load balancers require 2 public subnets (e.g. `subnet-xxxxxxxxxxxxxxxxx`)
 6. The name of an SSH key in AWS (must be in the same region where you are deploying)
 7. The domain you want to attach to the load balancer. It must exist in a Route53 hosted DNS zone (e.g. `hfw.aws.example.com`)
 8. The name of the Route53 hosted DNS zone (e.g. `example.com`)
 9. The admin password to use for Splunk (preferrably a long, random, alphanumeric string.  Special characters will cause problems).

After downloading this repo, open up [terraform.tfvars](terraform.tfvars) and edit it to add the above information in it.  Then open up `main.tf` and update the provider block (lines 2 and 3). Set the desired region to deploy in.  If you need to use an [AWS profile](https://docs.aws.amazon.com/sdk-for-php/v3/developer-guide/guide_credentials_profiles.html) set the profile name as well.  If your AWS credentials use the default profile (or don't need a profile) then just remove the `profile` line.

After making those changes and [making sure your AWS access credentials are available to Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs), simply run:

```
terraform init
terraform apply
```

`terraform init` is only required the first time you run.

## SSH

Your HFW can be administered via the admin UI, but it can also be administered via SSH.  The security group on the HFW is configured to only allow traffic from the bastion host.  By default the security group for the bastion host does not allow any incoming traffic.  Therefore to connect to the HFW via SSH you will first have to update the security group for the bastion host to allow traffic from your IP address.  Then you will be able to connect using the bastion host as a proxy.  That SSH command to connect to the HFW through the bastion host will look something like this:

```
ssh -i [SSH_PRIVATE_KEY_FILE] ec2-user@[HFW_PRIVATE_IP] -o "proxycommand ssh -W %h:%p -i [SSH_PRIVATE_KEY_FILE] ec2-user@[BASTION_HOST_PUBLIC_IP]"
```

You can lookup the ip addresses of your infrastructure using the AWS console or terraform will tell you if you execute:

```
terraform output
```

## The role of the Load Balancer

The load balancer is worth a quick mention because you may be wondering, "Why do I need a load balancer?"  It doesn't actually have anything to do with load balancing.  Rather, it simply serves as an SSL termination endpoint.  The underlying issue is that managing SSL certificates can be a pain.  If you wanted to you could get SSL certificates for your HFW using [Let's Encrypt](https://www.splunk.com/en_us/blog/cloud/secure-splunk-web-in-five-minutes-using-lets-encrypt.html), but turning on automatic renewals is not always easy and the steps to do it vary wildly depending on how you manage your application/DNS.

However, if you already have a Route53 hosted DNS zone in AWS, then you can use AWS to generate and automatically renew certificates (aka an ACM).  The problem there is that you cannot get that certificate into the EC2 instance for Splunk to use because [an ACM cannot be copied into an AWS EC2 instance](https://aws.amazon.com/premiumsupport/knowledge-center/configure-acm-certificates-ec2/).

What you can do though, is to use the ACM with a load balancer and point your domain to the load balancer.  With this setup the load balancer acts as an SSL termination endpoint.  It provides a valid SSL certificate to the browser and then passes traffic along to the splunk HFW.  Traffic between the load balancer and the HFW would then be encypted or not depending on how the HFW is configured.  In this case [the accompanying Packer repo](https://github.com/Cimpress-MCP/splunk-heavy-forwarder-packer-ami) configures Splunk to encrypt traffic with its own self-signed SSL certificate.  AWS load balancers don't mind self-signed certificates, so you end up with fully encrypted traffic between the internet and the HFW, with very little effort.

## Data inputs

It's common to have other pieces of infrastructure send data to a HFW.  There are two ways to send data to a HFW, and both require infrastructure changes so you need to understand how this deployment supports them.

### HTTP Event Collector (HEC)

A [Splunk HEC endpoint](https://dev.splunk.com/enterprise/docs/devtools/httpeventcollector/) is more or less just an HTTP API endpoint that you can send data to.  It requires authentication via an HEC token which must be sent with every request, but other than that the HEC more or less just let's you send whatever data you want and it will get forwarded onto splunk cloud and indexed.

Splunk uses a separate port for HEC traffic.  By default this is port 8088.  As a result the load balancer accepts traffic on port 8088 and forwards it to the HFW port 8088.  Therefore if you configure an HEC on your HFW you can send data to your HFW like this:

```
curl https://hfw.aws.example.com:8088/services/collector/event -H 'Authorization: Splunk [HEC_TOKEN]' -d 'your=data, goes=here'
```

### Splunk-to-Splunk

You can also configure a universal forwarder (UFW) or even another HFW to send data to your HFW, which will then pass it along to Splunk Cloud.  Splunk-to-Splunk traffic is typically sent and received on port 9997.  Splunk does **not** support sending Splunk-to-Splunk traffic through a load balancer.  Therefore if you wish to send data this way you must open up port 9997 on the security group for the HFW.  This is why the HFW is in a public subnet instead of a private one, since if it was in a private subnet you would not be able to easily grant access for Splunk-to-Splunk traffic.

**HOWEVER** Please keep in mind that by default Splunk-to-Splunk traffic is not encrypted, nor does the accompanying AMI configure encryption for Splunk-to-Splunk traffic.  Therefore if you decide to enable Splunk-to-Splunk traffic make sure and [enable encryption for it](https://docs.splunk.com/Documentation/Splunk/8.0.6/Security/Aboutsecuringdatafromforwarders).
