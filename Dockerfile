FROM alpine as resource

RUN apk add --update ca-certificates
RUN apk add --update curl
RUN apk add --update git
RUN apk add --update openssh-client
RUN apk add --update perl
RUN apk add --update ruby
RUN apk add --update ruby-json

ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*

FROM resource as tests
COPY . /resource

RUN apk add --update \
    ruby-bundler \
    ruby-io-console \
    ruby-dev \
    openssl-dev \
    alpine-sdk
RUN cd /resource && bundle install && bundle exec rspec

FROM resource
