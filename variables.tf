variable "app_name" {
  description = "The app name used for tagging infrastructure."
  type        = string
}

variable "additional_security_groups" {
  default     = []
  description = ""
  type        = list(string)
}

variable "availability_zones" {
  description = "A list of availability zones in the region"
  type        = list(string)
}

variable "db_instance_class" {
  description = ""
  type        = string
}

variable "engine" {
  default     = "aurora-mysql"
  description = ""
  type        = string
}

variable "environment" {
  description = "The environment in which this infrastructure will be provisioned."
  type        = string
}

variable "ingress_cidr_blocks" {
  description = "The CIDR block on which to allow ingress."
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnets which contain data resources."
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnets which contain data resources."
  type        = list(string)
}

variable "replica_count" {
  description = "Number of replicas in the cluster."
  type        = number
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "zone_id" {
  description = "The ID of the zone in which the DNS entry will be made, e.g. renkara.com."
  type        = string
}
