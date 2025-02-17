#!/bin/bash

# Print commands to the screen
set -x

# Catch Errors
set -euo pipefail

# Set variables
WORDPRESS_VERSION="6.7.2"
S3_UPLOADS_VERSION="3.0.7"

# Create file structure
mkdir -p plugins
mkdir -p themes

# Install plugins
composer install --no-dev -o

## Install s3-uploads plugin
if [ ! -d plugins/s3-uploads ]; then
  mkdir -p plugins/s3-uploads
  curl -OL https://github.com/humanmade/S3-Uploads/releases/download/${S3_UPLOADS_VERSION}/manual-install.zip
  unzip manual-install.zip -d plugins/s3-uploads
  rm -f manual-install.zip
fi

# Download WordPress
curl -O https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz
tar -xzf wordpress-${WORDPRESS_VERSION}.tar.gz
rm -rf wordpress-${WORDPRESS_VERSION}.tar.gz
rm -rf ./wordpress/wp-content/themes
rm -rf ./wordpress/wp-content/plugins
rsync -ravxc ./ ./wordpress/wp-content/ --exclude-from=./ci-scripts/rsync-excludes.txt
mv wordpress payload

set x