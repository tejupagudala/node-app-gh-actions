terraform {
  backend "s3" {
    bucket       = "tejupagudala-node-app-tfstate-589077667712"
    key          = "hire/node-app/terraform.tfstate"
    region       = "ap-south-2"
    encrypt      = true
    use_lockfile = true
  }
}
