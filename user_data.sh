#!/bin/bash
# Atualiza os pacotes
apt update -y

# Instala o servidor Apache
apt install apache2 -y

# Inicia e habilita o Apache para iniciar com o sistema
systemctl start apache2
systemctl enable apache2

# Cria uma página HTML simples
echo "<!DOCTYPE html>
<html>
  <head>
    <title>Servidor EC2 em Auto Scaling</title>
  </head>
  <body>
    <h1>Instância criada com sucesso via Auto Scaling!</h1>
    <p>Apache2 está em execução.</p>
  </body>
</html>" > /var/www/html/index.html
