## nginx + phpfpm docker image

image: fontenele/php

#### Branchs

- 7.2-nginx
- 7.3-nginx
- 7.4-nginx
- 8.0-nginx

#### Service config for docker-compose

```
version: '3.0'
services:
    web:
        image: fontenele/php:8.0-nginx
        container_name: name_of_container
        tty: true
        stdin_open: true
        working_dir: /var/www/html
        volumes:
            - ./:/var/www/html
```

###### Simplified for laravel
###### FonteSolutions - www.fontesolutions.com.br
