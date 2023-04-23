FROM debian:buster-slim

LABEL maintainer="Guilherme Fontenele <guilherme@fontenele.net>"

RUN apt-get update -qq && apt-get install -y apt-utils unzip zip tree curl net-tools wget git vim procps libcurl4 npm supervisor ca-certificates apt-transport-https sqlite3 cron \
        && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
	&& echo "deb https://packages.sury.org/php/ buster main" | tee /etc/apt/sources.list.d/php.list \
	&& apt-get update -qq && apt-get install -y nginx php8.2-fpm php8.2-gd php8.2-bcmath php8.2-bz2 php8.2-cli php8.2-intl php8.2-pdo php8.2-mbstring php8.2-pgsql php8.2-iconv php8.2-soap php8.2-sockets php8.2-mysql php8.2-zip php8.2-pgsql php8.2-sqlite php8.2-curl php8.2-xml php-imagick php-xdebug php-mongodb php-redis \
	&& mkdir /run/php && touch /run/php/php8.2-fpm.sock && touch /run/php/php8.2-fpm.pid && chmod -Rf 777 /var/lib/php/sessions

RUN openssl req -batch -nodes -newkey rsa:2048 -keyout /etc/ssl/private/server.key -out /tmp/server.csr -subj "/C=BR/ST=DF/L=Brasilia/O=Dev/OU=FS/CN=localhost" \
    && openssl x509 -req -days 365 -in /tmp/server.csr -signkey /etc/ssl/private/server.key -out /etc/ssl/certs/server.crt \
    && rm /tmp/server.csr

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
	&& ln -sf /dev/stderr /var/log/php8.2-fpm.log

#RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php/8.2/fpm/php.ini \
#    && sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/8.2/fpm/php.ini \
#    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/8.2/fpm/php.ini \
#    && echo "cgi.fix_pathinfo = 0;" >> /etc/php/8.2/cli/php.ini \
#    && sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/8.2/cli/php.ini \
#    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/8.2/cli/php.ini \
#    && sed -i 's/worker_connections 768/worker_connections 4096/g' /etc/nginx/nginx.conf

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer self-update --snapshot \
    && npm cache clean -f \
    && npm install -g n \
    && n stable && bash
RUN npm install npm@latest -g && bash
RUN npm i -g yarn

COPY entrypoint.sh /entrypoint.sh
COPY listener.php /listener.php
COPY nginx.conf.tpl /tmp/nginx.conf.tpl
COPY nginx_default.conf /etc/nginx/sites-enabled/default
COPY php-fpm.conf.tpl /tmp/php-fpm.conf.tpl
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

RUN echo "* * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1" > /var/spool/cron/crontabs/$(whoami)
RUN chmod 600 /var/spool/cron/crontabs/$(whoami)

RUN chmod 755 /entrypoint.sh
ENV OPENSSL_CONF="/etc/ssl/"

EXPOSE 80
EXPOSE 443

CMD ["supervisord"]
