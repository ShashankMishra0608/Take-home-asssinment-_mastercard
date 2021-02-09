#Variables#
#subnet range depends on the number of AZ a perticular region has so pass the sunbets accoundingly
#we have defined six subnets as the region has at max 6 Az available.
#---------------------------------------------------------------------------------------------------------------------
variable "name" {
  type        = string
  description = "The name of the resources"
  default     = "shnk-demo-aws"
}

variable "region" {
  type        = string
  description = "The name of the region you wish to deploy into"
  default     = "us-east-1"
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24","10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "private_subnets_A" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24","10.0.23.0/24", "10.0.24.0/24", "10.0.25.0/24"]
}

variable "private_subnets_B" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = ["10.0.30.0/24", "10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24", "10.0.34.0/24", "10.0.35.0/24"]
}

variable "public_inbound_acl_rules" {
  description = "Public subnets inbound network ACLs"
  type        = list(map(string))

  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "public_outbound_acl_rules" {
  description = "Public subnets outbound network ACLs"
  type        = list(map(string))

  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "custom_inbound_acl_rules" {
  description = "Custom subnets inbound network ACLs"
  type        = list(map(string))

  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "custom_outbound_acl_rules" {
  description = "Custom subnets outbound network ACLs"
  type        = list(map(string))

  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "pub_cidr_blocks" {
  description = "List of IPv4 CIDR ranges to use on all egress rules"
  type        = string
  default     = "0.0.0.0/0"
}
variable "name" {
  description = "Name to associate with the launch template"
}

variable "user_data" {
  description = "Encoded user data"
  default     = null
}


variable "image_id" {
  description = "AMI image identifier"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "iam_instance_profile" {
  description = "Name of IAM instance profile associated with launched instances"
  default     = null
}

variable "asg_security_groups" {
  description = "List of security group names to attach"
  default     = []
}

variable "associate_public_ip_address" {
  description = "Allocation a public IP address (required for Internet access)"
  default     = true
}

variable "metadata_v2" {
  description = "Enforce metadata version 2"
  default     = true
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "The desired number of EC2 Instances in the ASG"
  type        = number
  default     = 4
}

variable "key_name" {
  description = "ec2_key_pair_name"
  type        = string
  default     = "asg_keypair"