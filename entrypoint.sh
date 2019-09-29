#!/bin/sh

set -e

bundle install --jobs 4 --quiet
bundle exec srb tc > /srb-tc-output.txt

ruby parse_results.rb /src-tc-output.txt
