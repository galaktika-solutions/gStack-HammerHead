FROM ubuntu:bionic-20180821

ENV DEBIAN_FRONTEND noninteractive

# locales
RUN apt-get update && apt-get install -y locales
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN apt-get update && apt-get install -y curl gnupg
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get update && apt-get install -y nodejs
RUN npm install -g npm@6.4.1

# python
RUN apt-get update && apt-get install -y python3.6 python3-venv
RUN python3.6 -m venv /python
ENV PATH /python/bin:$PATH
ENV PYTHONUNBUFFERED 1

RUN pip install --no-cache-dir \
  gdockutils==0.5.7

ENV HOME /tmp
WORKDIR /src/js_client
ENV PATH $PATH:./node_modules/.bin

ENTRYPOINT ["/src/docker/node/entrypoint.sh"]
