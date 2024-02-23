terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-bucket-terraform2135"
    key            = "terraform/modules"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lockid"
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}


resource "aws_launch_configuration" "launch-config" {
  name            = "launch-config"
  image_id        = "ami-0e731c8a588258d0d"
  instance_type   = "t2.micro"
  user_data       = <<-EOF
  #!/bin/bash

  # Actualizar el índice de paquetes
  sudo yum update -y

  # Instalar Apache
  sudo yum install httpd -y

  # Iniciar el servicio de Apache
  sudo systemctl start httpd

  # Habilitar Apache para que se inicie en el arranque del sistema
  sudo systemctl enable httpd

  # Crear un index para que sea visible desde el servidor web
  echo "<html><head><title>Mi Página</title></head><body><h1>Bienvenido a mi página web</h1></body></html>" > /var/www/html/index.html

  # Mostrar el estado del servicio de Apache
  sudo systemctl status httpd
  EOF
  security_groups = [aws_security_group.apache_security_group.id]
}


resource "aws_autoscaling_group" "my-autoescaling-group" {
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  launch_configuration = aws_launch_configuration.launch-config.name
  health_check_type    = "EC2"
  vpc_zone_identifier  = module.vpc.private_subnets
  target_group_arns    = [aws_lb_target_group.target-group-apache.arn]

    enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

}

resource "aws_lb_target_group" "target-group-apache" {
  name     = "target-group-apache"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

}


resource "aws_autoscaling_policy" "autoescaling-policy-apache" {
  name                   = "example-autoscaling-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.my-autoescaling-group.name
}



//Load balancer configuration

resource "aws_lb" "my-lb-apache" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.apache_security_group.id]
  subnets            = module.vpc.public_subnets


}

resource "aws_lb_listener" "listener-lb-apache" {
  load_balancer_arn = aws_lb.my-lb-apache.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group-apache.arn
  }
}






