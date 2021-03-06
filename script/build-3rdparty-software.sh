#!/usr/bin/env bash

# =========================================================================
# | Builds all 3rdparty software packages so that the project can then be
# | built on top of them.
# =========================================================================

# Basic information about this script
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(pwd)/$(dirname $0)"

# Other variables
SOFTWARE_PACKAGES="fuego"
BUILD_SCRIPT="$SCRIPT_DIR/build-software.sh"

if test $# -ne 0; then
  echo "$SCRIPT_NAME: No arguments supported."
  echo ""
  echo "This script will execute BUILD_SCRIPT for each of the SOFTWARE_PACKAGES:"
  echo "SOFTWARE_PACKAGES = $SOFTWARE_PACKAGES"
  echo "BUILD_SCRIPT = $BUILD_SCRIPT"
  exit 1
fi

if test ! -x "$BUILD_SCRIPT"; then
  echo "Build script $BUILD_SCRIPT not found"
  exit 1
fi

for SOFTWARE_PACKAGE in $SOFTWARE_PACKAGES; do
  $BUILD_SCRIPT -q $SOFTWARE_PACKAGE
  if test $? -ne 0; then
    echo "Build failed for software package "$SOFTWARE_PACKAGE""
    exit 1
  fi
  echo ""
done
