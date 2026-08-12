#!/bin/sh
set -e

# Generate config.php dari environment variables jika belum ada.
# Tidak menimpa config.php yang sudah ada (misal hasil instalasi yang sudah jalan).
if [ ! -f /var/www/html/config.php ]; then
    cat > /var/www/html/config.php <<'PHPEOF'
<?php
global $CFG;
$CFG = new stdClass();

// Database.
$CFG->dbtype    = getenv('MOODLE_DB_TYPE') ?: 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = getenv('MOODLE_DB_HOST') ?: 'db';
$CFG->dbname    = getenv('MOODLE_DB_NAME') ?: 'moodle';
$CFG->dbuser    = getenv('MOODLE_DB_USER') ?: 'moodle';
$CFG->dbpass    = getenv('MOODLE_DB_PASSWORD') ?: 'moodlepass';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = ['dbport' => '', 'dbcollation' => 'utf8mb4_unicode_ci'];

// Web location.
$CFG->wwwroot   = getenv('MOODLE_WWWROOT') ?: 'http://localhost:8080';
$CFG->routerconfigured = true;

// Data directory.
$CFG->dataroot  = getenv('MOODLE_DATAROOT') ?: '/var/www/moodledata';
$CFG->directorypermissions = 02777;

// Development settings.
if (getenv('MOODLE_DEBUG') === '1') {
    @error_reporting(E_ALL);
    @ini_set('display_errors', '1');
    $CFG->debug = (E_ALL);
    $CFG->debugdisplay = 1;
    $CFG->noemailever = true;
}

require_once(__DIR__ . '/lib/setup.php');
PHPEOF
    chown www-data:www-data /var/www/html/config.php
    echo "config.php generated from environment."
fi

exec "$@"
