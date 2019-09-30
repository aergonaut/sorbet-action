#!/bin/sh

set -ex

cd $GITHUB_WORKSPACE
bundle install --jobs 4 --quiet

ruby /parse_results.rb
