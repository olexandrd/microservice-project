# Standard RDS Instance
resource "aws_db_instance" "standard" {
  count                   = var.use_aurora ? 0 : 1
  identifier              = var.name
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  username                = var.username
  password                = var.password
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = var.multi_az
  publicly_accessible     = var.publicly_accessible
  backup_retention_period = var.backup_retention_period
  parameter_group_name    = aws_db_parameter_group.standard[0].name

  tags = var.tags
}

# Standard parameter group
resource "aws_db_parameter_group" "standard" {
  count       = var.use_aurora ? 0 : 1
  name        = "${var.name}-rds-params"
  family      = var.parameter_group_family_rds
  description = "Standard RDS PG for ${var.name}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }

  tags = var.tags
}
