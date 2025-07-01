resource "aws_security_group" "worker" {
  name        = "${var.name}-worker-sg"
  description = "K8s Worker Node SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Kubelet"
  }
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "NodePort"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecr_pull" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "alb_controller" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetSubnets"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:ListServerCertificates",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:GetServerCertificate"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["shield:DescribeProtection", "shield:GetSubscriptionState"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["waf-regional:GetWebACLForResource", "waf-regional:GetWebACL", "waf-regional:AssociateWebACL", "waf-regional:DisassociateWebACL"]
    resources = ["*"]
  }
}

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
  name               = "${var.name}-ec2-role-worker"
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

resource "aws_iam_role_policy" "allow_ecr_pull" {
  name   = "${var.name}-allow-ecr-pull"
  role   = aws_iam_role.ec2_instance_role.id
  policy = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_role_policy" "allow_alb" {
  name   = "${var.name}-alb-controller"
  role   = aws_iam_role.ec2_instance_role.id
  policy = data.aws_iam_policy_document.alb_controller.json
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-ec2-profile-worker"
  role = aws_iam_role.ec2_instance_role.name
}

# resource "aws_instance" "worker" {
#   count           = var.worker_count
#   ami             = var.ami
#   instance_type   = var.instance_type
#   subnet_id       = var.subnet_id
#   security_groups = [aws_security_group.worker.id]

#   root_block_device {
#     volume_size = 32
#     volume_type = "gp3"
#   }

#   user_data = base64encode(templatefile("${path.module}/cloud_init_worker.sh.tpl", {
#     kubeadm_join_cmd = var.kubeadm_join_cmd
#   }))
#   tags = {
#     Name = "${var.name}-worker-${count.index + 1}"
#   }
# }

resource "aws_launch_template" "nodes_lt" {
  name_prefix   = "${var.name}-lt"
  image_id      = var.ami
  instance_type = var.instance_type

  user_data = base64encode(templatefile("${path.module}/cloud_init_worker.sh.tpl", {
    kubeadm_token_ssm_name = var.kubeadm_token_ssm_name,
    ca_hash_ssm_name       = var.ca_hash_ssm_name,
    master_ip              = var.master_private_ip,
    region                 = var.region
  }))
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.worker.id]
  }

}
resource "aws_autoscaling_group" "nodes_asg" {
  vpc_zone_identifier = [for subnet in var.subnet_id : subnet]
  min_size            = var.worker_count
  max_size            = var.worker_count
  desired_capacity    = var.worker_count

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.nodes_lt.id
        version            = "$Latest"
      }
    }
    instances_distribution {
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-worker"
    propagate_at_launch = true
  }
}
