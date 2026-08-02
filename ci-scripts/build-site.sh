#!/bin/bash

# Print commands to the screen
set -x

# Catch Errors
set -euo pipefail

# Set variables
WORDPRESS_VERSION="7.0.2"

# Create file structure
mkdir -p plugins
mkdir -p themes

# Install plugins
composer install --no-dev -o

# Download WordPress
curl -O https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz
tar -xzf wordpress-${WORDPRESS_VERSION}.tar.gz
rm -rf wordpress-${WORDPRESS_VERSION}.tar.gz
rm -rf ./wordpress/wp-content/themes
rm -rf ./wordpress/wp-content/plugins
rsync -ravxc ./ ./wordpress/wp-content/ --exclude-from=./ci-scripts/rsync-excludes.txt
mv wordpress payload

set x
