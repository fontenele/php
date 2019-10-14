FROM debian:buster-slim

LABEL maintainer="Guilherme Fontenele <guilherme@fontenele.net>"

RUN apt-get update -qq && apt-get install -y apt-utils unzip zip tree curl net-tools wget git vim procps libcurl4 npm supervisor ca-certificates apt-transport-https \
        && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
	&& echo "deb https://packages.sury.org/php/ buster main" | tee /etc/apt/sources.list.d/php.list \
	&& apt-get update -qq && apt-get install -y nginx php7.2-fpm php7.2-gd php7.2-bcmath php7.2-bz2 php7.2-cli php7.2-intl php7.2-pdo php7.2-mbstring php7.2-pgsql php7.2-iconv php7.2-soap php7.2-sockets php7.2-mysql php7.2-zip php7.2-curl php7.2-xml php-xdebug \
	&& mkdir /run/php && touch /run/php/php7.2-fpm.sock && touch /run/php/php7.2-fpm.pid && chmod -Rf 777 /var/lib/php/sessions
	
ENV OPENSSL_CONF="/etc/ssl/"

RUN openssl req -batch -nodes -newkey rsa:2048 -keyout /etc/ssl/private/server.key -out /tmp/server.csr -subj "/C=BR/ST=DF/L=Brasilia/O=Dev/OU=FS/CN=localhost" \
    && openssl x509 -req -days 365 -in /tmp/server.csr -signkey /etc/ssl/private/server.key -out /etc/ssl/certs/server.crt \
    && rm /tmp/server.csr

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
	&& ln -sf /dev/stderr /var/log/php7.2-fpm.log

#RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php/7.3/fpm/php.ini \
#    && sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/7.3/fpm/php.ini \
#    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/7.3/fpm/php.ini \
#    && echo "cgi.fix_pathinfo = 0;" >> /etc/php/7.3/cli/php.ini \
#    && sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/7.3/cli/php.ini \
#    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/7.3/cli/php.ini \
#    && sed -i 's/worker_connections 768/worker_connections 4096/g' /etc/nginx/nginx.conf

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require hirak/prestissimo \
    && npm cache clean -f \
    && npm install -g n \
    && n stable && bash
RUN npm install npm@latest -g && bash
RUN npm i -g yarn

COPY entrypoint.sh /entrypoint.sh
COPY listener.php /listener.php
COPY nginx.conf.tpl /tmp/nginx.conf.tpl
COPY php-fpm.conf.tpl /tmp/php-fpm.conf.tpl
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

RUN chmod 755 /entrypoint.sh

EXPOSE 80
EXPOSE 443

CMD ["supervisord"]
