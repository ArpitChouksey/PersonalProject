resource "aws_launch_template" "dev_nginx_template" {
  name = "dev-nginx-template"

  image_id      = "ami-0c101f26f147fa7fd"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.dev_private_ec2_sg.id]

  iam_instance_profile {
    name = "dev-ec2-ssm-role"
  }

  user_data = base64encode(<<EOF
#!/bin/bash

dnf update -y
dnf install -y nginx

systemctl enable nginx
systemctl start nginx

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
-H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
-s http://169.254.169.254/latest/meta-data/instance-id)

echo "<h1>DEV Shared VPC App</h1>" > /usr/share/nginx/html/index.html
echo "<h2>Instance: $INSTANCE_ID</h2>" >> /usr/share/nginx/html/index.html
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "dev-nginx-instance"
    }
  }
}
