# gStack

Docker based setup for a simple Django-Postgres-Nginx stack

```sh
docker pull galaktikasolutions/gstack-main
docker run --rm -it -v "$(pwd):/project_root" galaktikasolutions/gstack-main demo_setup
sudo docker-compose up
```

The `run` command with options:

```sh
docker run --rm -it -v "$(pwd):/project_root" \
  -e "HOST_NAME=gstack.dev" \
  -e "NETWORK_SUBNET=10.7.11.0/24" \
  -e "COMPOSE_PROJECT_NAME=gstackdemo" \
  galaktikasolutions/gstack-main demo_setup
```
