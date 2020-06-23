variable "application_name" {
  type = string
  description = "the name of the application this cicd is going to build"
}

variable "branch" {
  type = string
  description = "the source code branch to build"
}

variable "repository_name" {
  type = string
  description = "the name of the codecommit repository"
}