module "vpc-app" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-app"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    terraform   = "true"
    Environment = "dev"
  }

}



resource "aws_security_group" "app_security_group" {
  name        = "app-security-group"
  description = "Security Group para servidor app"
  vpc_id      = module.vpc-app.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-security-group"
  }
}


module "vpc-bastion"{
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-bastion"

  azs             = ["us-east-1a"]

  public_subnets  = ["10.0.1.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    terraform   = "true"
    Environment = "bastion"
  }

}

resource "aws_security_group" "bastion_security_group" {
  name        = "app-security-group"
  description = "Security Group para servidor bastion"
  vpc_id      = module.vpc-bastion.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-security-group"
  }
}

resource "aws_ec2_transit_gateway" "app_transit_gateway" {
  description = "TransitGateway to get communication to bastion and aplication app"
  tags = {
    Name = "app_transit_gateway"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "attachment_vpc_app" {
  transit_gateway_id = aws_ec2_transit_gateway.app_transit_gateway.id
  vpc_id             = module.vpc-app.vpc_id
  subnet_ids = module.vpc-app.private_subnets
}

resource "aws_ec2_transit_gateway_vpc_attachment" "attachment_vpc_bastion" {
  transit_gateway_id = aws_ec2_transit_gateway.app_transit_gateway.id
  vpc_id             = module.vpc-bastion.vpc_id
  subnet_ids = module.vpc-bastion.public_subnets
}







