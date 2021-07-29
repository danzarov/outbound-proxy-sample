provider "aws" {}

resource "aws_cloudformation_stack" "vpc_pub_priv" {
  capabilities = ["CAPABILITY_NAMED_IAM"]

  name = "${var.env_name}-vpc"

  tags = {
    envname = var.env_name
  }

  disable_rollback = false
  template_body    = file("vpc.yaml")
}

# todo -  create a security group on vpc.yaml/outputs and pass it to outbound below via parameters

resource "aws_cloudformation_stack" "outbound_proxy" {
  depends_on = [
    aws_cloudformation_stack.vpc_pub_priv
  ]

  capabilities = ["CAPABILITY_NAMED_IAM"]

  name = "${var.env_name}-outbound-sample"

  parameters = {
    VpcId          = aws_cloudformation_stack.vpc_pub_priv.outputs["VpcId"]
    PublicSubnet1  = aws_cloudformation_stack.vpc_pub_priv.outputs["PublicSubnet1"]
    PublicSubnet2  = aws_cloudformation_stack.vpc_pub_priv.outputs["PublicSubnet2"]
    PrivateSubnet1 = aws_cloudformation_stack.vpc_pub_priv.outputs["PrivateSubnet1"]
    PrivateSubnet2 = aws_cloudformation_stack.vpc_pub_priv.outputs["PrivateSubnet2"]
    KeyName        = var.key_name
  }

  tags = {
    envname = var.env_name
  }

  disable_rollback = false
  template_body    = file("outbound_proxy.yaml")
}

resource "aws_cloudformation_stack" "dummy_instance" {
  depends_on = [
    aws_cloudformation_stack.outbound_proxy
  ]

  capabilities = ["CAPABILITY_NAMED_IAM"]

  name = "${var.env_name}-dummy-instance"

  parameters = {
    InstancesSecurityGroup = aws_cloudformation_stack.vpc_pub_priv.outputs["InstancesSecurityGroup"]
    PublicSubnet1          = aws_cloudformation_stack.vpc_pub_priv.outputs["PublicSubnet1"]
    KeyName                = var.key_name
  }

  tags = {
    envname = var.env_name
  }

  disable_rollback = false
  template_body    = file("dummy_instance.yaml")
}

