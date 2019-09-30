#!/bin/sh

set -ex

cd $GITHUB_WORKSPACE
bundle install --jobs 4 --quiet

set +e
bundle exec srb tc 2> ./srb-tc-output.txt

set -e
ruby /parse_results.rb ./src-tc-output.txt
