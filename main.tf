module "pipeline" {
  source = "./cicd_pipeline"

  application_name = var.application_name
  branch = "master"
  repository_name = var.application_code_reponame
}