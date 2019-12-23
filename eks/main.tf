variable "service_name" {
  default = "k8s"
}

variable "env" {
  default = "sand"
}

variable "cidr_block" {
  default = ""
}

variable "region" {
  default = "us-east-1"
}

variable "availability_zone" {
  default = {
    "us-east-1a" = 1
    "us-east-1b" = 2
    "us-east-1c" = 3
  }
}

variable "own_ip" {}

variable "my_key" {}

provider "aws" {
  region  = var.region
  version = "~> 2.40.0"
}
