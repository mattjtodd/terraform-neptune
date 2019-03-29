variable "neptune_name" {
  default = "neptune-cluster-demo"
}

variable "neptune_sg_name" {
  default = "neptune-sg"
}

variable "neptune_count" {
  default = 2
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "key_name" {
  default = "ssh-tunnel"
}
