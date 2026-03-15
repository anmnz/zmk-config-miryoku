#!/usr/bin/env bash
set -euo pipefail

# Build firmware for my keyboards
# Assumes that zmk/, zmk-config/ and zmk-modules/ are next to each other
# and that this script is in one of them.

PRISTINE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -p) PRISTINE="-p"; shift ;;
    *)  echo "Unknown argument: $1"; exit 1 ;;
  esac
done

cd "$(dirname "$0")"
ZMK_CONFIG_DIR="$(realpath ../zmk-config)"
ZMK_MODULES_DIR="$(realpath ../zmk-modules)"
cd ../zmk/app

OUTPUT_DIR="$ZMK_CONFIG_DIR"/build
mkdir -p $OUTPUT_DIR
rm -rf ${OUTPUT_DIR:?}/*

build () {
  name="$1"
  shift
  shields="$*"
  build_dir="build/$name"

  echo "#### Building $name in $build_dir ####"

  west build $PRISTINE -d "$build_dir" -b nice_nano_v2 -S miryoku --  \
    -DSHIELD="$shields"                                                \
    -DZMK_CONFIG="$ZMK_CONFIG_DIR/config"                             \
    -DZMK_EXTRA_MODULES="$ZMK_CONFIG_DIR;$ZMK_MODULES_DIR/sofle-hybrid-ergomech-zmk"

  cp -v "$build_dir/zephyr/zmk.uf2" "$OUTPUT_DIR/zmk_$name.uf2"

  echo "#### Finished building $name ####"
}

build settings_reset settings_reset
build sofle_left     sofle_ergomech_left
build sofle_right    sofle_ergomech_right
build chocofi_left   corne_left  nice_view_adapter nice_view
build chocofi_right  corne_right nice_view_adapter nice_view

##
