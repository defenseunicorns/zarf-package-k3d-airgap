# variables.tf

# Variables for general information
##############################################
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-gov-west-1"
}

variable "owner" {
  description = "Configuration owner"
  type        = string
  default     = "MikeA"
}

variable "aws_region_az" {
  description = "AWS region availability zone"
  type        = string
  default     = "a"
}

# Variables for VPC
######################################
 
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
 
variable "vpc_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}
 
variable "vpc_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}
 
 
# Variables for Security Group
######################################
 
variable "sg_ingress_proto" {
  description = "Protocol used for the ingress rule"
  type        = string
  default     = "tcp"
}
 
variable "sg_ingress_ssh" {
  description = "Port used for the ingress rule"
  type        = string
  default     = "22"
}
 
variable "sg_egress_proto" {
  description = "Protocol used for the egress rule"
  type        = string
  default     = "-1"
}
 
variable "sg_egress_all" {
  description = "Port used for the egress rule"
  type        = string
  default     = "0"
}
 
variable "sg_egress_cidr_block" {
  description = "CIDR block for the egress rule"
  type        = string
  default     = "0.0.0.0/0"
}
 
 
# Variables for Subnet
######################################
 
variable "sbn_public_ip" {
  description = "Assign public IP to the instance launched into the subnet"
  type        = bool
  default     = true
}
 
variable "sbn_cidr_block" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}
 
 
# Variables for Route Table
######################################
 
variable "rt_cidr_block" {
  description = "CIDR block for the route table"
  type        = string
  default     = "0.0.0.0/0"
}
 
 
# Variables for Instance
######################################
 
variable "instance_ami" {
  description = "ID of the AMI used"
  type        = string
  default     = "ami-00df7c0a2c7039cf9" 
  # ami-0fdfc2b8d05c8e319 Amazon Linux 2023 AMI x86_64
  # Red Hat Enterprise Linux 9 (HVM), SSD Volume Type - ami-00df7c0a2c7039cf9 (64-bit x86)
}
 
variable "instance_type" {
  description = "Type of the instance"
  type        = string
  default     = "p3.8xlarge"
}   # p3.2xlarge - 8 cpu / 61 GB RAM / 1 GPU V100 16GB VRAM 3.802 USD per Hour RHEL
    # p3.8xlarge	32 cpu x86_64 / 244 GB RAM / 4 16 GB v100 GPUs

variable "key_pair" {
  description = "SSH Key pair used to connect"
  type        = string
  default     = "MikeA-KP"
}
 
variable "root_device_type" {
  description = "Type of the root block device"
  type        = string
  default     = "gp3"
}
 
variable "root_device_size" {
  description = "Size of the root block device"
  type        = string
  default     = "200"
}