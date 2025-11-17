# state.tf
terraform {
  backend "s3" {
    bucket  = "terraform-state-lucas"
    key     = "site/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
    use_lockfile = true

  }
}
