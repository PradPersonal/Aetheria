# Production environment configuration
aws_region   = "ca-central-1"  # Main region, ACM certificates for CloudFront will use us-east-1
project_name = "aetheria"
environment  = "prod"

# Production domains (replace with your actual domains)
domain_name     = "aetheria.com"
api_domain_name = "api.aetheria.com"
cdn_domain_name = "cdn.aetheria.com"

# Production VPC
vpc_cidr = "10.0.0.0/16"

# Production EKS configuration
kubernetes_version = "1.28"
node_group_instance_types = ["t3.large", "t3.xlarge"]
node_group_desired_size = 3
node_group_min_size = 2
node_group_max_size = 10

# Production optimizations
enable_spot_instances = false  # Use on-demand for reliability
cloudfront_price_class = "PriceClass_All"  # Global distribution

# Production lifecycle
media_bucket_lifecycle_days = 90
logs_bucket_lifecycle_days = 365
backup_retention_days = 90

# Production security
enable_waf = true
allowed_cidr_blocks = [
  "0.0.0.0/0"  # In production, restrict this to office/VPN IPs
]

# Full monitoring
enable_vpc_flow_logs = true
enable_eks_logging = true