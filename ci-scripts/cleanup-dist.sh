#!/bin/bash

# Print commands to the screen
set -x

# Catch Errors
set -euo pipefail

# Delete built files

echo "Deleting built files"
rm -rf payload wordpress plugins themes vendor object-cache.php

set x