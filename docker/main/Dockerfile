FROM ubuntu:bionic-20181112

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update

# locales
RUN apt-get install -y locales wget build-essential
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# # LaTex
# RUN apt-get install -y latexmk
# ENV PATH /texlive/bin/x86_64-linux:$PATH
# COPY conf/texlive.profile /
# RUN wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
#     && tar -zxf install-tl-unx.tar.gz \
#     && ./install-tl-*/install-tl -profile /texlive.profile \
#     && rm -rf install-tl-unx.tar.gz \
#     && rm -rf install-ts-* \
#     && rm -rf /usr/share/doc/ \
#     && rm -rf /usr/share/man/
# RUN find /texlive/texmf-var -type d -exec chmod 777 {} +

# postgres
ENV PG_MAJOR 10
RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres
RUN apt-get update && apt-get install -y postgresql-common
RUN sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf
RUN apt-get update && apt-get install -y postgresql-$PG_MAJOR
ENV PATH $PATH:/usr/lib/postgresql/$PG_MAJOR/bin
ENV PGDATA /data/postgres

# python
RUN apt-get update && apt-get install -y python3.6 python3.6-dev python3-venv
RUN python3.6 -m venv /python
ENV PATH /python/bin:$PATH
ENV PYTHONPATH /src/django_project/
ENV PYTHONUNBUFFERED 1

# django
RUN apt-get update && apt-get install -y gettext
RUN groupadd -r django --gid=8000 && useradd -r -m -g django --uid=8000 django
ENV DJANGO_SETTINGS_MODULE core.settings

# pip packages
RUN pip install --no-cache-dir \
  django==2.1.3 \
  psycopg2-binary==2.7.5 \
  uwsgi==2.0.17.1 \
  django-debug-toolbar==1.10.1 \
  coverage==4.5.1 \
  sphinx==1.8.1 \
  sphinx_rtd_theme==0.4.2 \
  gdockutils==0.5.9

# nginx
RUN groupadd -r nginx --gid=4430 && useradd -r -g nginx --uid=4430 nginx
RUN apt-get update && apt-get install -y nginx
RUN ln -sf /dev/stdout /var/log/nginx/access.log

# copy
COPY / /src
RUN chown -R django:django /src
WORKDIR /src

ENTRYPOINT ["/src/docker/main/entrypoint.sh"]
