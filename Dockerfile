FROM php:8.4-apache-bookworm

# ============================================================
# Moodle 5.2.2 — PHP 8.4 + Apache
# DocumentRoot = /var/www/html/public (struktur baru Moodle 5.x)
# ============================================================

# System dependencies untuk build ekstensi PHP dan runtime Moodle.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libicu-dev \
        libxml2-dev \
        libxslt1-dev \
        libzip-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libcurl4-openssl-dev \
        libonig-dev \
        libmariadb-dev \
        libsodium-dev \
        ghostscript \
        libxml2 \
        libxslt1.1 \
        default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Ekstensi PHP yang dibutuhkan Moodle (termasuk sodium yang wajib di 5.2).
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        mysqli \
        pdo_mysql \
        gd \
        intl \
        zip \
        opcache \
        exif \
        soap \
        xsl \
        mbstring \
        curl \
        xml \
        dom \
        xmlreader \
        iconv \
        fileinfo \
        sodium \
    && docker-php-ext-enable opcache

# Konfigurasi PHP untuk Moodle.
RUN { \
        echo 'memory_limit=256M'; \
        echo 'max_input_vars=5000'; \
        echo 'upload_max_filesize=512M'; \
        echo 'post_max_size=512M'; \
        echo 'max_execution_time=300'; \
        echo 'opcache.enable=1'; \
        echo 'opcache.enable_cli=0'; \
        echo 'opcache.memory_consumption=256'; \
        echo 'opcache.max_accelerated_files=20000'; \
    } > /usr/local/etc/php/conf.d/moodle.ini

# Aktifkan mod_rewrite dan arahkan DocumentRoot ke public/.
RUN a2enmod rewrite headers
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

# Entrypoint untuk generate config.php dari env (dev setup dengan bind mount).
COPY docker/entrypoint.sh /usr/local/bin/moodle-entrypoint
RUN chmod +x /usr/local/bin/moodle-entrypoint

# Copy source Moodle.
COPY . /var/www/html/
WORKDIR /var/www/html

# www-data harus bisa menulis (bind mount akan menimpa di runtime).
RUN chown -R www-data:www-data /var/www/html \
    && mkdir -p /var/www/moodledata \
    && chown www-data:www-data /var/www/moodledata

EXPOSE 80

ENTRYPOINT ["moodle-entrypoint"]
CMD ["apache2-foreground"]
