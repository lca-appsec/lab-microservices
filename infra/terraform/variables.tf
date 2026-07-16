variable "namespace" {
  type    = string
  default = "application"
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "image_registry" {
  type = string
}

variable "services" {
  type = list(string)
}
