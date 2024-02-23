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