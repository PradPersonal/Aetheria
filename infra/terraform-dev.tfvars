# Development environment specific configuration
aws_region   = "ca-central-1"
project_name = "aetheria"
environment  = "dev"

# Use example domains for development
domain_name     = "dev.aetheria.example.com"
api_domain_name = "api-dev.aetheria.example.com"
cdn_domain_name = "cdn-dev.aetheria.example.com"

# Smaller VPC for development
vpc_cidr = "10.0.0.0/16"

# Cost optimization for development
node_group_instance_types = ["t3.medium"]
node_group_desired_size = 1
node_group_min_size = 1
node_group_max_size = 3

# Enable cost optimizations
enable_spot_instances = true
cloudfront_price_class = "PriceClass_100"

# Reduced retention for development
media_bucket_lifecycle_days = 7
logs_bucket_lifecycle_days = 14
backup_retention_days = 7

# Security (less strict for development)
enable_waf = false  # Disable WAF in dev to reduce costs
allowed_cidr_blocks = ["0.0.0.0/0"]

# Monitoring (reduced for cost)
enable_vpc_flow_logs = false
enable_eks_logging = true