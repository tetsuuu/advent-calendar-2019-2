variable "service_name" {}

variable "env" {}

variable "user_name" {}

variable "user_passwd" {}

variable "location" {
  default = "us-east1-b"
}

variable "machine" {
  default = "n1-standard-1"
}

provider "google" {
  credentials = file("credentials/advent_account.json")
  project     = "advent-calendar-2019-2"
  region      = "us-east1"
  zone        = "us-east1-b"
}
