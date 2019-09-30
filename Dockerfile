FROM ruby:2.6

COPY entrypoint.sh /entrypoint.sh
COPY parse_results.rb /parse_results.rb

ENTRYPOINT ["/entrypoint.sh"]
