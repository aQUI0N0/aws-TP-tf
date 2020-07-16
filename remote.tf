terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "epsi-yann"

    workspaces {
      name = "aws-TP-tf"
    }
  }
}
