resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = { Name = var.name }
}

# Public subnet

resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.newbits, count.index + var.newbits / 2)
  availability_zone = data.aws_availability_zones.current.names[count.index]

  tags = { Name = "${var.name}-public-${count.index}" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = var.name }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = local.tags

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags       = { Name = var.name }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = { Name = var.name }
}

## ALB configuration

resource "aws_security_group" "lb_sg" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow inbound traffic to ${var.app_name} Load Balancer"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_lb_http" {
  security_group_id            = aws_security_group.lb_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
  referenced_security_group_id = var.expose_to_internet ? null : aws_security_group.lb_sg.id
}

resource "aws_lb" "lb" {
  name               = var.app_name
  load_balancer_type = "application"
  internal           = var.expose_to_internet ? false : true
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true

  access_logs {
    enabled = true
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "alb/${var.app_name}-alb"
  }
}

resource "aws_lb_listener" "my_service" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_service.arn
  }
}

resource "aws_lb_target_group" "my_service" {
  name     = "${var.app_name}-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Private subnet

resource "aws_subnet" "private" {
  count = var.private_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.newbits, count.index)
  availability_zone = data.aws_availability_zones.current.names[count.index]

  tags = { Name = "${var.name}-private-${count.index}" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = local.tags

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "my_service_sg" {
  name        = "${var.app_name}-sg"
  description = "Allow inbound traffic to ${var.app_name} app and all outbound traffic"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id            = aws_security_group.my_service_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
  referenced_security_group_id = aws_security_group.lb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_db_traffic" {
  security_group_id            = aws_security_group.my_service_sg.id
  from_port                    = -1
  ip_protocol                  = "tcp"
  to_port                      = local.db_port[var.db_engine]
  referenced_security_group_id = aws_security_group.lb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.my_service_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_db_subnet_group" "my_service" {
  name       = var.app_name
  subnet_ids = [ for subnet in aws_subnet.private : subnet.id ]
}
