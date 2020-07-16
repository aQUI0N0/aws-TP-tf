terraform {
  backend "s3" {
    bucket = "epsi-yann"
    key    = "epsi/terraform.tfstate"
    region = "us-east-1"
  }
}