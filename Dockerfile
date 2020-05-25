FROM debian:buster-slim

LABEL maintainer="Guilherme Fontenele <guilherme@fontenele.net>"

RUN apt-get update -qq && apt-get install -y apt-utils unzip zip tree curl net-tools wget git vim procps npm supervisor sqlite3 \
	nginx php7.3-fpm php7.3-gd php7.3-bcmath php7.3-bz2 php7.3-cli php7.3-intl php7.3-mbstring php7.3-zip php7.3-curl php7.3-xml php7.3-mysql php7.3-pgsql php7.3-sqlite3 php-xdebug \
	&& mkdir /run/php && touch /run/php/php7.3-fpm.sock && touch /run/php/php7.3-fpm.pid

RUN openssl req -batch -nodes -newkey rsa:2048 -keyout /etc/ssl/private/server.key -out /tmp/server.csr -subj "/C=BR/ST=DF/L=Brasilia/O=Dev/OU=FS/CN=localhost" \
    && openssl x509 -req -days 365 -in /tmp/server.csr -signkey /etc/ssl/private/server.key -out /etc/ssl/certs/server.crt \
    && rm /tmp/server.csr

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
	&& ln -sf /dev/stderr /var/log/php7.3-fpm.log

#RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php/7.3/fpm/php.ini \
#    && sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/7.3/fpm/php.ini \
#    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/7.3/fpm/php.ini \
#    && echo "cgi.fix_pathinfo = 0;" >> /etc/php/7.3/cli/php.ini \
#    && sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/7.3/cli/php.ini \
#    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/7.3/cli/php.ini \
#    && sed -i 's/worker_connections 768/worker_connections 4096/g' /etc/nginx/nginx.conf

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require hirak/prestissimo \
    && npm i -g yarn

COPY entrypoint.sh /entrypoint.sh
COPY listener.php /listener.php
COPY nginx.conf.tpl /tmp/nginx.conf.tpl
COPY php-fpm.conf.tpl /tmp/php-fpm.conf.tpl
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

RUN chmod 755 /entrypoint.sh

EXPOSE 80
EXPOSE 443

CMD ["supervisord"]
