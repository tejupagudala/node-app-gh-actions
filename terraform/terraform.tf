terraform {
  backend "s3" {
    bucket       = "tejupagudala-node-app-tfstate-589077667712"
    key          = "hire/node-app/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
