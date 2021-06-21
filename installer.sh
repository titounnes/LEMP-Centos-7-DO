#!/usr/bin/bash
#update system
yum update -y

#install nginx
echo "install epel-release..."
yum install epel-release -y
echp "install nginx..."
yum install nginx -y
echo "enable nginx"
systemctl enable nginx
echo "start nginx"
systemctl start nginx

#install firewall
echo "install firewall"
yum install firewalld -y
echo "running firewll daemon.."
systemctl enable firewalld
systemctl start firewalld
echo "open port 80..."
firewall-cmd --permanent --zone=public --add-service=http 
echo "open port 443..."
firewall-cmd --permanent --zone=public --add-service=https
echo "reload firewalld"
firewall-cmd --reload

#install maruadb
echo "install mariadb"
yum install mariadb-server -y
echo "start mariadb"
systemctl start mariadb.service
systemctl enable mariadb
mysql_secure_installation

#install php7.4

dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y
dnf module enable php:remi-7.4 -y
dnf install php php-cli php-common php-fpm php-xml php-intl php-mysql php-pdo php-mbstring -y

systemctl enable php-fpm
systemctl start php-fpm

echo "Create document root."
if [ -d "/var/www/example" ] 
then
	echo "Directory /var/www/example is already exists."
else
	mkdir "/var/www/example"
fi

sed -i 's/default_server;/;/g' "/etc/nginx/nginx.conf"

#config example.com
rm /etc/nginx/conf.d/example.conf -f
{
        echo 'server {'
        echo '  listen 80 default_server;'
        echo '  root /var/www/example/;'
        echo '  index index.php;'
        echo '  server_name example.com;'
        echo '  '
        echo '  location / { '
        echo '     try_files $uri $uri/ /index.php;'
	echo '   }'
        echo '  '
	echo '   location ~ .php$ {'
	echo '      try_files $uri =404;'
	echo '      fastcgi_pass unix:/run/php-fpm/www.sock;'
	echo '      fastcgi_index index.php;'
	echo '      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;'
	echo '      include fastcgi_params;'
	echo '   }'
	echo '}'
} >> /etc/nginx/conf.d/example.conf

rm "/var/www/example/info.php" -f

{
	echo '<?php'
	echo 'phpinfo();'
} >> /var/www/example/info.php

#reload nginx
echo "Reload webserver..."
systemctl restart nginx

echo "please connect to http://your_ip_public/info.php
