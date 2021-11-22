FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

# Get and build the Drakonhub

RUN apt-get update && apt-get install -y \
  git \
  tcl8.6 \
  tk8.6 \
  tcllib \
  libsqlite3-tcl \
  libtk-img \
  unzip \
  wget \
  default-jre-headless \
  zip

WORKDIR /root
RUN wget -O drakon_editor.zip https://sourceforge.net/projects/drakon-editor/files/drakon_editor1.31.zip/download
RUN unzip drakon_editor.zip -d drakon_editor

WORKDIR /
RUN git clone https://github.com/stepan-mitkin/drakonhub.git drakonhub
WORKDIR /drakonhub
RUN chmod +x static/drnjs app/drnlua
RUN ./build

# Installing Tarantool
# https://www.tarantool.io/en/download/os-installation/ubuntu/
RUN apt-get update && apt-get install -y \
  gnupg2 \
  curl \
  lsb-release \
  apt-transport-https

RUN curl -L https://tarantool.io/KPJlDeI/release/2.6/installer.sh | bash
RUN apt-get update && apt-get install -y \
  tarantool \
  luarocks \
  lua-sec \
  expat \
  libexpat1-dev

# Install tarantool modules

RUN luarocks install luautf8
RUN luarocks install luaexpat
RUN luarocks install luasoap

# Create directory structure

RUN mkdir /dewt

WORKDIR /dewt

RUN mkdir app
RUN mkdir data
RUN mkdir emails
RUN mkdir feedback
RUN mkdir journal
RUN mkdir logs
RUN mkdir ssl
RUN mkdir static
RUN mkdir tmp
RUN mkdir content
RUN mkdir read

# Create an empty external_creds module
RUN echo "return {}" > app/external_creds.lua

# Let the tarantool user own the folders
RUN chown -R tarantool /dewt

# Install tarantool-http
# https://github.com/tarantool/http#installation
WORKDIR /dewt/app
RUN tarantoolctl rocks install http

# Make a release zip
WORKDIR /drakonhub/scripts
RUN ./deploy /tmp/*.zip

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8090
CMD ["/usr/bin/tarantool", "/dewt/app/onprem.lua"]
