#  Galaktika Solutions - Software Stack
[![Requirements Status](https://requires.io/github/galaktika-solutions/gStack/requirements.svg?branch=readme)](https://requires.io/galaktika-solutions/gStack/requirements/?branch=readme)

# `.env`
```env
COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml
COMPOSE_PROJECT_NAME=gstacktest
ENV=DEV
REGISTRY_URL=gstacktest
VERSION=latest
HOST_NAME=dev.gstacktest.net
SERVER_IP=127.0.0.1
BACKUP_UID=1000
```

# `.secret.env`
```env
DJANGO_SECRET_KEY=
DB_PASSWORD=
CERTIFICATE_CACERT=
CERTIFICATE_CRT=
CERTIFICATE_KEY=
```

TODO
- Debug toolbar
- Coverage + test running
- SQL explorer
- Email settings
- Documentation generations
