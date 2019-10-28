#!/bin/sh
yarn stdver

yarn build

gem install gems
gem install dpl
