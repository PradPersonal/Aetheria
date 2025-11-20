# Aetheria AWS Infrastructure with Terraform

This directory contains Terraform configuration files to deploy the complete AWS infrastructure for the Aetheria streaming platform.

## Architecture Overview

The infrastructure includes:

- **VPC** with multiple AZs (public subnets for ALB/NAT, private subnets for EKS nodes)
- **EKS Cluster** with managed node groups and IRSA enabled
- **ECR Repositories** for each microservice with image scanning and lifecycle policies
- **S3 Buckets** for media storage (versioned) and logs/analytics
- **CloudFront Distribution** with signed URLs/cookies for secure content delivery
- **ACM Certificates** (us-east-1 for CloudFront, regional for ALB)
- **Route 53** hosted zone with DNS records
- **WAF** with AWS managed rules for CloudFront and ALB
- **Application Load Balancer** for EKS ingress

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Domain name** that you control (for DNS configuration)
4. **kubectl** for EKS management (optional)

## Quick Start

### 1. Configure Variables

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit the variables file with your values
# At minimum, change the domain names to domains you own
vim terraform.tfvars
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan the Deployment

```bash
# Development environment
terraform plan -var-file="terraform-dev.tfvars"

# Production environment
terraform plan -var-file="terraform-prod.tfvars"
```

### 4. Deploy Infrastructure

```bash
# Development environment
terraform apply -var-file="terraform-dev.tfvars"

# Production environment
terraform apply -var-file="terraform-prod.tfvars"
```

### 5. Configure kubectl

```bash
# Get the kubectl configuration command from outputs
terraform output configure_kubectl

# Run the command (example)
aws eks --region ca-central-1 update-kubeconfig --name aetheria-dev-cluster
```

## Environment Configurations

### Development (`terraform-dev.tfvars`)
- **Cost optimized**: Smaller instances, spot instances enabled
- **Single AZ**: NAT gateway to reduce costs
- **Reduced retention**: Shorter backup and log retention
- **WAF disabled**: To reduce costs
- **Minimal monitoring**: VPC flow logs disabled

### Production (`terraform-prod.tfvars`)
- **High availability**: Multi-AZ deployment
- **Performance optimized**: Larger instances, on-demand
- **Full security**: WAF enabled with managed rules
- **Extended retention**: Longer backup and log retention
- **Comprehensive monitoring**: All logging enabled

## Cost Estimates

### Development Environment
- EKS Control Plane: ~$73/month
- EKS Nodes (1x t3.medium): ~$30/month
- ALB: ~$20/month
- NAT Gateway (1): ~$45/month
- S3/CloudFront/Route53: ~$20/month
- **Total**: ~$190/month

### Production Environment
- EKS Control Plane: ~$73/month
- EKS Nodes (3x t3.large): ~$150/month
- ALB: ~$25/month
- NAT Gateways (3): ~$135/month
- WAF: ~$10/month
- S3/CloudFront: Variable (usage-based)
- **Total**: ~$400-600/month + usage

## Security Features

### Network Security
- Private subnets for EKS nodes
- Security groups with least privilege
- VPC endpoints for AWS services
- WAF with AWS managed rule sets

### Data Protection
- S3 bucket encryption (AES-256)
- HTTPS everywhere (ACM certificates)
- CloudFront signed URLs for premium content
- IAM roles with minimal permissions

### Compliance
- CloudTrail logging to S3
- VPC Flow Logs (optional)
- WAF logging to CloudWatch
- Resource tagging for governance

## Monitoring & Logging

### CloudWatch
- EKS control plane logs
- WAF request logs
- ALB access logs
- Custom dashboards

### S3 Logging
- ALB access logs
- CloudFront access logs  
- CloudTrail logs
- Application logs (via Fluent Bit)

## DNS Configuration

After deployment, you'll need to:

1. **Update your domain's nameservers** to point to Route 53:
   ```bash
   terraform output route53_zone_name_servers
   ```

2. **Verify DNS propagation**:
   ```bash
   dig NS your-domain.com
   ```

3. **Test SSL certificates**:
   ```bash
   curl -I https://your-domain.com
   curl -I https://api.your-domain.com
   curl -I https://cdn.your-domain.com
   ```

## EKS Setup

### Install Required Add-ons

```bash
# Install AWS Load Balancer Controller
kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_full.yaml

# Install Cluster Autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Install External DNS (optional)
kubectl apply -f https://github.com/kubernetes-sigs/external-dns/releases/download/v0.13.1/external-dns.yaml
```

### Verify Cluster

```bash
# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -A

# Test connectivity
kubectl run test-pod --image=nginx --rm -it -- curl http://google.com
```

## Application Deployment

### ECR Repositories

Push your container images to the ECR repositories:

```bash
# Get ECR repository URLs
terraform output ecr_repository_urls

# Login to ECR
aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ca-central-1.amazonaws.com

# Tag and push images
docker tag aetheria-web:latest <ecr-url>/aetheria-web:latest
docker push <ecr-url>/aetheria-web:latest
```

### S3 Configuration

Configure your application to use the S3 buckets:

```bash
# Get bucket names
terraform output media_bucket_name
terraform output s3_access_role_arn

# Use IRSA role ARN in your Kubernetes service accounts
```

## Troubleshooting

### Common Issues

1. **Domain validation fails**:
   - Ensure you control the domain
   - Check DNS propagation
   - Verify Route 53 hosted zone

2. **EKS nodes not joining**:
   - Check IAM roles and policies
   - Verify security group rules
   - Check subnet routing

3. **ALB not accessible**:
   - Verify security groups
   - Check target group health
   - Ensure DNS records point to ALB

4. **CloudFront not serving content**:
   - Check S3 bucket policy
   - Verify Origin Access Control
   - Test direct S3 access

### Useful Commands

```bash
# Check Terraform state
terraform show
terraform state list

# Get specific outputs
terraform output vpc_id
terraform output cluster_name

# Refresh state
terraform refresh -var-file="terraform-dev.tfvars"

# Destroy specific resource
terraform destroy -target=aws_instance.example

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0
```

## Cleanup

To destroy the infrastructure:

```bash
# Development
terraform destroy -var-file="terraform-dev.tfvars"

# Production (be very careful!)
terraform destroy -var-file="terraform-prod.tfvars"
```

## File Structure

```
infra/
├── main.tf                    # Main configuration and providers
├── variables.tf               # Input variables
├── locals.tf                  # Local values and data sources  
├── outputs.tf                 # Output values
├── vpc.tf                     # VPC and networking
├── eks.tf                     # EKS cluster and IRSA roles
├── ecr.tf                     # ECR repositories
├── s3.tf                      # S3 buckets and policies
├── route53.tf                 # DNS and certificates
├── cloudfront.tf              # CDN configuration
├── alb.tf                     # Application Load Balancer
├── waf.tf                     # Web Application Firewall
├── terraform.tfvars.example   # Example variables
├── terraform-dev.tfvars       # Development configuration
├── terraform-prod.tfvars      # Production configuration
└── functions/
    └── security-headers.js    # CloudFront function
```

## Best Practices

### Security
- Use least privilege IAM policies
- Enable MFA for AWS accounts
- Regularly rotate access keys
- Monitor CloudTrail logs

### Cost Optimization
- Use spot instances for non-critical workloads
- Set up billing alerts
- Regular review unused resources
- Use appropriate storage classes

### Operations
- Use remote state with locking
- Tag all resources consistently
- Document all changes
- Test in development first

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review AWS documentation
3. Check Terraform provider documentation
4. Open an issue in the project repository