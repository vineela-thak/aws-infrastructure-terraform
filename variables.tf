variable "aws_region" {
  default = "us-east-2"
}

variable "web_ami" {
  default = "ami-01aab85a5e4a5a0fe"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  type    = "list"
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnets_cidr" {
  type    = "list"
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "azs" {
  type    = "list"
  default = ["us-east-2a", "us-east-2b"]
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_key" {
  default = "onica"
}

variable "aws_autoscaling_group_capacity" {
  type = "map"

  default = {
    min      = 2
    desired  = 2
    max_size = 2
  }
}

variable "aws_autoscaling_policy_up" {
  type = "map"

  default = {
    scaling_adjustment = 1
    adjustment_type    = "ChangeInCapacity"
    cooldown           = 300
  }
}

variable "aws_autoscaling_policy_down" {
  type = "map"

  default = {
    scaling_adjustment = -1
    adjustment_type    = "ChangeInCapacity"
    cooldown           = 300
  }
}
