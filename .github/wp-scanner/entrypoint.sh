#!/bin/bash

set -eo pipefail
set -x

# Define shell colors
SHELL_END="\033[0m"
SHELL_RED="\033[0;31m"
SHELL_GREEN="\033[0;32m"
# Set wp-content directory location
WP_CONTENT_DIR="${INPUT_CONTENT_DIR:-$GITHUB_WORKSPACE}"
# Set PHP syntax check variables
OUTPUT_REDIRECT=""
FAILED_MESSAGE_POSTFIX=""
# Set WordPress core version
WORDPRESS_VERSION=${INPUT_WP_CORE_VERSION:-$(curl -s "https://api.wordpress.org/core/version-check/1.7/" | jq -r '[.offers[]|select(.response=="upgrade")][0].version')}

# Function to print red text
function shell_red {
  echo -e "${SHELL_RED}${1}${SHELL_END}"
}

# Function to print green text
function shell_green {
  echo -e "${SHELL_GREEN}${1}${SHELL_END}"
}

# Function to perform PHP syntax check
function php_syntax_check {
  [ "${INPUT_PHPSYNTAX_ENABLE_DEBUG}" = "true" ] && OUTPUT_REDIRECT="1>/dev/null" && FAILED_MESSAGE_POSTFIX=" - set the phpsyntax_enable_debug input to true and re-run the scanner to find out all errors"
  shell_green "##### Starting PHP syntax check #####"

  # The -P10 option specifies the number of parallel processes (In constrainted CPUs will take approx time for 1 available cpu)
  if ! find "${WP_CONTENT_DIR}" -type f -name '*.php' -not -path '*/vendor/*' -print0 | xargs -0 -P10 -I {} bash -c "php -l {} ${OUTPUT_REDIRECT}"; then
    shell_red "The PHP syntax check finished with errors${FAILED_MESSAGE_POSTFIX}"
  else
    shell_green "The PHP syntax check finished without errors"
  fi

  # If no_fail input is set to true, exit without failure even if there are errors
  if [ "${INPUT_NO_FAIL}" = "true" ]; then
    exit 0
  fi
}

# Function to perform virus scan
function virus_scan {
  if [ "${INPUT_VIRUS_SCAN_UPDATE}" = "true" ]; then
    echo "Updating ClamAV definitions database"
    freshclam --verbose
  fi

  shell_green "##### Starting virus scan #####"
  if ! clamscan --exclude-dir ./.composer-cache --exclude-dir ./node_modules_cache -riz "${WP_CONTENT_DIR}"; then
    shell_red "**** INFECTED FILE(S) FOUND!!! **** PLEASE SEE REPORT ABOVE ****"
  else
    shell_green "Clean - No infected files found"
  fi

  # If no_fail input is set to true, exit without failure even if there are errors
  if [ "${INPUT_NO_FAIL}" = "true" ]; then
    exit 0
  fi
}

# Function to setup MariaDB
function setup_mariadb {
  echo "Setting up MariaDB"
  
  # Start MariaDB
  /etc/init.d/mariadb start

  # Set a password for the root user
  mysqladmin -u root password password

  # Create WordPress database
  mysql -u root -e "CREATE DATABASE wordpress;"
}

# Function to install and configure WordPress
function setup_wordpress {
  echo "Setting up WordPress"
  
  # Install composer dependencies
  if [ "${INPUT_COMPOSER_BUILD}" = "true" ]; then
    composer install --no-dev
  fi

  # Download WordPress core
  curl -O https://wordpress.org/wordpress-"${WORDPRESS_VERSION}".tar.gz
  tar -xzf wordpress-"${WORDPRESS_VERSION}".tar.gz
  rm -rf wordpress-"${WORDPRESS_VERSION}".tar.gz
  rm -rf ./wordpress/wp-content/*
  rsync -raxc "${WP_CONTENT_DIR}" ./wordpress/wp-content/ --exclude=wordpress \
    --exclude=wp-config.php \
    --exclude=.git* \
    --exclude=db.php \
    --exclude=object-cache.php \
    --exclude=advanced-cache.php

  # Install WordPress
  pushd wordpress
  wp --allow-root config create --dbname=wordpress --dbuser=root --dbpass=password --dbhost=127.0.0.1
  wp --allow-root core install --url=10upvulnerabilitytest.net --title='WordPress Vulnerability Test' --admin_user=admin --admin_password=password --admin_email=10upvulnerabilitytest@example.net --skip-email
  popd
}

# function to execute WordPress vulnerability scan
function wp_vuln_scan {
  echo "Setting up WordPress vulnerability scan"

  # Install and configure wpcli-vulnerability-scanner package
  wp --allow-root package install 10up/wpcli-vulnerability-scanner:dev-trunk
  pushd wordpress
  wp --allow-root config set VULN_API_PROVIDER "${INPUT_VULN_API_PROVIDER}"
  wp --allow-root config set VULN_API_TOKEN "${INPUT_VULN_API_TOKEN}"

  # Run WordPress themes vulnerability scan
  shell_green "##### Starting WordPress Themes vulnerability scan #####"
  THEMES_SCAN_OUTPUT=$(wp --allow-root vuln theme-status | grep -v 'Vulnerability API Provider' | grep -v 'status' | grep -v 'No vulnerabilities reported for this version of')
  if [ -z "${THEMES_SCAN_OUTPUT}" ]; then
    shell_green "No theme vulnerabilities found"
  else
    wp --allow-root vuln theme-status --reference --format=yaml
    shell_red "**** THEME VULNERABILITIES FOUND!!! **** PLEASE SEE REPORT ABOVE ****"
  fi

  # Run WordPress Plugins vulnerability scan
  shell_green "##### Starting WordPress Plugins vulnerability scan #####"
  PLUGINS_SCAN_OUTPUT=$(wp --allow-root vuln plugin-status | grep -v 'Vulnerability API Provider' | grep -v 'status' | grep -v 'No vulnerabilities reported for this version of')
  if [ -z "${PLUGINS_SCAN_OUTPUT}" ]; then
    shell_green "No plugin vulnerabilities found"
  else
    wp --allow-root vuln plugin-status --reference --format=yaml
    shell_red "**** PLUGIN VULNERABILITIES FOUND!!! **** PLEASE SEE REPORT ABOVE ****"
  fi
  popd

  # If no_fail input is set to true, exit without failure even if there are errors
  if [ "${INPUT_NO_FAIL}" = "true" ]; then
    exit 0
  fi
}

# Execute PHP syntax check if not disabled
[ "${INPUT_DISABLE_PHPSYNTAX_CHECK}" != "true" ] && php_syntax_check

# Execute virus scan if not disabled
[ "${INPUT_DISABLE_VIRUS_SCAN}" != "true" ] && virus_scan

# Execute WordPress vulnerability scan if not disabled
[ "${INPUT_DISABLE_WP_VULN_SCAN}" != "true" ] && setup_mariadb && setup_wordpress && wp_vuln_scan
