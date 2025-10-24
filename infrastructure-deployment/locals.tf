locals {
  tags = {
    project = var.name
  }
  db_port = {
    "mysql" = 3306
    "postgresql" = 5432
  }
}
