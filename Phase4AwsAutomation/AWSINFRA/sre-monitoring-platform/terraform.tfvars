region = "us-east-1"

email_address = "arpitchouksey18@gmail.com"

cluster_name = "sre-eks"

node_group_name = "sre-nodegroup"

cluster_role_name = "eks-cluster-role"

node_role_name = "eks-node-role"

instance_name = "sre-monitor-server"

instance_type = "t3.micro"

instance_types = [
  "t3.medium"
]

ami_id = "ami-00e801948462f718a"

sg_name = "sre-platform-sg"

sg_description = "Allows needed ports"

allowed_ip = "49.43.5.164/32"

trail_name = "sre-cloudtrail"

cloudtrail_bucket_name = "aws-cloudtrail-logs-211811255273-a4f95133"

topic_name = "sre-alerts"

email = "arpitchouksey18@gmail.com"

allowed_ports = [
  22,
  3000,
  5601,
  9090,
  16686
]

dynamodb_table_name  = "terraform-locks"

dynamodb_billing_mode = "PAY_PER_REQUEST"
