FROM ruby:2.3.1-alpine
MAINTAINER tommyku

COPY Gemfile Gemfile.lock /app/

WORKDIR /app/

RUN bundle

COPY . /app/

CMD [ "ruby", "kmb-eta-unofficial-bot.rb" ]
