#!/bin/sh
yarn stdver

yarn build

yes y | gem uninstall dpl
yes y | gem uninstall gems
