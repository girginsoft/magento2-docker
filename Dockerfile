FROM ubuntu:16.04

MAINTAINER girginsoft <girginsoft@gmail.com>

ENV MYSQL_USER=mysql \
    MYSQL_DATA_DIR=/var/lib/mysql \
    MYSQL_RUN_DIR=/run/mysqld \
    MYSQL_LOG_DIR=/var/log/mysql

RUN apt-get update && apt-get install -y apt-utils
RUN echo "mysql-server mysql-server/root_password password ''" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password ''" | debconf-set-selections
#installing required packages
RUN apt-get install -y mysql-server \
  && rm -rf ${MYSQL_DATA_DIR}


RUN apt-get install -y nginx php7.0-fpm php7.0-fpm php7.0-common php7.0-gd php7.0-mysql php7.0-mcrypt php7.0-curl php7.0-intl php7.0-xsl php7.0-mbstring php7.0-zip php7.0-bcmath php7.0-iconv php7.0-opcache php7.0-soap php7.0-json php7.0-xml curl git


ENV nginx_vhost /etc/nginx/sites-available/default
ENV php_conf /etc/php/7.0/fpm/php.ini
ENV nginx_conf /etc/nginx/nginx.conf

COPY conf/nginx-site.conf /etc/nginx/sites-available/default

#Php-fpm config on nginx virt host
RUN sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' ${php_conf}

#Creating php-fpm sock folder and change ownership web server directory
RUN mkdir -p /run/php && chown -R www-data:www-data /var/www/html && chown -R www-data:www-data /run/php
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
#Defining volume for  persistent data and configs
VOLUME ["/var/www/html",  "/var/lib/mysql", "/run/mysqld", "/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]

COPY conf/composer-auth.json /root/.composer/auth.json
COPY run.sh /run.sh
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

#make run.sh runnable
RUN chmod 755 /run.sh

WORKDIR /var/www/html
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/run.sh"]

EXPOSE 80 443 3306
