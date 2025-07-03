resource "aws_security_group" "control_plane" {
  name        = "${var.name}-cp-sg"
  description = "K8s Control Plane SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K8s API"
  }
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "BGP for Calico"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ssm_parameters" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory",
      "ssm:PutParameter"
    ]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/k8s/*"
    ]
  }
}

resource "aws_iam_role" "ec2_instance_role" {
  name               = "${var.name}-ec2-role-control-plane"
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

resource "aws_iam_role_policy" "ssm_parameters" {
  name   = "${var.name}-ssm-parameter-access"
  role   = aws_iam_role.ec2_instance_role.id
  policy = data.aws_iam_policy_document.ssm_parameters.json
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-ec2-profile-control-plane"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_instance" "control_plane" {
  ami                  = var.ami
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  security_groups      = [aws_security_group.control_plane.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 32
    volume_type = "gp3"
  }

  user_data_base64 = base64encode(templatefile("${path.module}/cloud_init_master.sh.tpl", {
    kubeadm_token_ssm_name = var.kubeadm_token_ssm_name,
    ca_hash_ssm_name       = var.ca_hash_ssm_name,
    region                 = var.region,
    pod_network_cidr       = var.pod_network_cidr,
  }))
  tags = {
    Name = "${var.name}-control-plane"
  }
}


