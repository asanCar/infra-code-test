variable "name" {
  type        = string
  default     = "cint-code-test"
  description = "Root name for resources in this project"
}

variable "vpc_cidr" {
  default     = "10.1.0.0/16"
  type        = string
  description = "VPC cidr block"
}

variable "newbits" {
  default     = 8
  type        = number
  description = "How many bits to extend the VPC cidr block by for each subnet"
}

variable "public_subnet_count" {
  default     = 3
  type        = number
  description = "How many subnets to create"
}

variable "private_subnet_count" {
  default     = 3
  type        = number
  description = "How many private subnets to create"
}

variable "app_name" {
  type = string
  description = "Name of the application to be deployed"
  default = "my-service"
}

variable "instance_type" {
  type = string
  description = "EC2 instance type to be used to deploy our application"
  default = "t2-nano"
}

variable "expose_to_internet" {
  type = bool
  description = "Should the application be expose to the Internet?"
  default = false
}

variable "db_engine" {
  type = string
  description = "Database engine to be used (e.g. mysql, postgres, etc.)"
  default = "mysql"
}

variable "db_engine_version" {
  type = string
  description = "Database engine version to be used"
  default = "8.0"
}

variable "db_storage_size" {
  type = number
  description = "Amount of space in GB of the Database instances"
  default = 10
}

variable "db_instance_size" {
  type = string
  description = "Instance class of the Database instances"
  default = "db.t3.micro"
}

variable "db_username" {
  type = string
  description = "Username for the root database user"
}

variable "db_password" {
  type = string
  description = "Password for the root database user"
}