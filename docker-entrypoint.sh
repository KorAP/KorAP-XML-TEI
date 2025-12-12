#!/bin/sh
set -e

# Execute tei2korapxml with all passed arguments
# Use the installed version from /usr/local/bin
exec /usr/local/bin/tei2korapxml "$@"
