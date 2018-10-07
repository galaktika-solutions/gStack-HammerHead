FROM ubuntu:bionic-20180821

ENV DEBIAN_FRONTEND noninteractive

# locales
RUN apt-get update
RUN apt-get install -y locales wget latexmk build-essential rsync gettext
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# LaTex
ENV PATH /texlive/bin/x86_64-linux:$PATH
COPY conf/texlive.profile /
RUN wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
    && tar -zxf install-tl-unx.tar.gz \
    && ./install-tl-*/install-tl -profile /texlive.profile \
    && rm -rf install-tl-unx.tar.gz \
    && rm -rf install-ts-* \
    && rm -rf /usr/share/doc/ \
    && rm -rf /usr/share/man/
RUN find /texlive/texmf-var -type d -exec chmod 777 {} +

# postgres
ENV PG_MAJOR 10
RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres
RUN apt-get install -y postgresql-common
RUN sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf
RUN apt-get install -y postgresql-$PG_MAJOR
ENV PATH $PATH:/usr/lib/postgresql/$PG_MAJOR/bin
ENV PGDATA /data/postgres

# python
RUN apt-get install -y python3.6 python3-venv
RUN python3.6 -m venv /python
ENV PATH /python/bin:$PATH
ENV PYTHONPATH /src/django_project/
ENV PYTHONUNBUFFERED 1

# django
RUN groupadd -r django --gid=8000 && useradd -r -m -g django --uid=8000 django
ENV DJANGO_SETTINGS_MODULE core.settings

# uwsgi
RUN apt-get install -y build-essential
RUN apt-get install -y python3.6-dev
RUN apt-get install -y gcc
RUN apt-get install -y git

# pip packages
RUN pip install --no-cache-dir \
  django==2.1.1 \
  psycopg2-binary==2.7.5 \
  uwsgi==2.0.17.1 \
  django-debug-toolbar==1.10.1 \
  git+https://github.com/galaktika-solutions/django-sql-explorer.git \
  XlsxWriter==1.1.1 \
  django-extensions==2.1.2 \
  coverage==4.5.1 \
  periodtask==0.5.5 \
  django-mailer==1.2.5 \
  coverage==4.5.1 \
  Sphinx==1.8.1 \
  sphinx_rtd_theme==0.4.2 \
  djangorestframework==3.8.2

# nginx
RUN groupadd -r nginx --gid=4430 && useradd -r -g nginx --uid=4430 nginx
RUN apt-get install -y nginx
RUN ln -sf /dev/stdout /var/log/nginx/access.log

# copy
COPY / /src
WORKDIR /src
RUN find /src -type d -exec chmod 777 {} +

ENTRYPOINT ["/src/docker/main/entrypoint.sh"]
