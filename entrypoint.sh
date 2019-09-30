#!/bin/sh

set -e

cd $GITHUB_WORKSPACE
bundle install --jobs 4 --quiet
bundle exec srb tc > /srb-tc-output.txt

ruby /parse_results.rb /src-tc-output.txt
