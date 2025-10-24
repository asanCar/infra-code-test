# Load Balancer logs S3 configuration
resource "aws_s3_bucket" "lb_logs" {
  bucket = "${var.app_name}-lb-logs"
}

resource "aws_s3_bucket_public_access_block" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_lb_write_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  policy = data.aws_iam_policy_document.allow_lb_write_logs.json
}

data "aws_iam_policy_document" "allow_lb_write_logs" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.lb_logs.arn,
      "${aws_s3_bucket.lb_logs.arn}/*",
    ]
  }
}

# Amazon RDS configuration

resource "aws_db_instance" "my_service" {
  allocated_storage      = var.db_storage_size
  db_name                = "${var.app_name}-db"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_size
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.my_service.name
  vpc_security_group_ids = [aws_security_group.my_service_sg.id]
}
