// AWS target region
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "notify_target_email" {
  type    = string
  default = ""
}
