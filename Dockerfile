FROM debian:buster-slim

LABEL maintainer="Guilherme Fontenele <guilherme@fontenele.net>"

RUN apt-get update -qq && apt-get install -y apt-utils unzip zip tree curl net-tools wget git vim procps libcurl4 npm supervisor ca-certificates apt-transport-https sqlite3 cron \
        && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
	&& echo "deb https://packages.sury.org/php/ buster main" | tee /etc/apt/sources.list.d/php.list \
	&& apt-get update -qq && apt-get install -y nginx php7.4-fpm php7.4-gd php7.4-bcmath php7.4-bz2 php7.4-cli php7.4-intl php7.4-pdo php7.4-mbstring php7.4-pgsql php7.4-iconv php7.4-soap php7.4-sockets php7.4-mysql php7.4-zip php7.4-pgsql php7.4-sqlite php7.4-curl php7.4-xml php-imagick php-xdebug php-mongodb php-redis \
	&& mkdir /run/php && touch /run/php/php7.4-fpm.sock && touch /run/php/php7.4-fpm.pid && chmod -Rf 777 /var/lib/php/sessions

RUN openssl req -batch -nodes -newkey rsa:2048 -keyout /etc/ssl/private/server.key -out /tmp/server.csr -subj "/C=BR/ST=DF/L=Brasilia/O=Dev/OU=FS/CN=localhost" \
    && openssl x509 -req -days 365 -in /tmp/server.csr -signkey /etc/ssl/private/server.key -out /etc/ssl/certs/server.crt \
    && rm /tmp/server.csr

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
	&& ln -sf /dev/stderr /var/log/php7.4-fpm.log

#RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php/7.3/fpm/php.ini \
#    && sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/7.3/fpm/php.ini \
#    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/7.3/fpm/php.ini \
#    && echo "cgi.fix_pathinfo = 0;" >> /etc/php/7.3/cli/php.ini \
#    && sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/7.3/cli/php.ini \
#    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/7.3/cli/php.ini \
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
COPY php-fpm.conf.tpl /tmp/php-fpm.conf.tpl
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

RUN echo "* * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1" > /var/spool/cron/crontabs/$(whoami)
RUN chmod 600 /var/spool/cron/crontabs/$(whoami)

RUN chmod 755 /entrypoint.sh
ENV OPENSSL_CONF="/etc/ssl/"

EXPOSE 80
EXPOSE 443

CMD ["supervisord"]
