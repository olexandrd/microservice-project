# Public Route Table and Routes
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table and Routes
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Using NAT instance instead of NAT Gateway
# NAT Gateway for Private Subnets
# resource "aws_eip" "nat" {
#   tags = {
#     Name = "${var.vpc_name}-nat-eip"
#   }
# }
# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public[0].id

#   tags = {
#     Name = "${var.vpc_name}-nat-gw"
#   }
# }


data "aws_ami" "nat_amzn2_arm64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
}

resource "aws_security_group" "nat_sg" {
  name        = "${var.name}-nat-sg"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    Name = "${var.name}-nat-sg"
  }
}
resource "aws_iam_role" "ec2_instance_role" {
  name               = "${var.name}-ec2-role-nat"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-ec2-profile-nat"
  role = aws_iam_role.ec2_instance_role.name
}
resource "aws_instance" "nat_instance" {
  ami                         = data.aws_ami.nat_amzn2_arm64.id
  instance_type               = "t4g.nano"
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.nat_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y iptables-services
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/00-ip-forwarding.conf
    sysctl -p /etc/sysctl.d/00-ip-forwarding.conf
    iptables -t nat -A POSTROUTING -s ${var.vpc_cidr_block} -j MASQUERADE
    iptables -P FORWARD ACCEPT
    service iptables save
    systemctl enable iptables.service
    systemctl restart iptables.service
    EOF

  tags = {
    Name = "${var.name}-nat-instance"
  }
}

locals {
  nat_eni_id = aws_instance.nat_instance.primary_network_interface_id
}


resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = local.nat_eni_id
  depends_on             = [aws_instance.nat_instance]
  lifecycle {
    create_before_destroy = true
  }
}
