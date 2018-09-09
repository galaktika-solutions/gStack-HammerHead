# coding: utf-8
# Django core and 3rd party imports
import os.path


SECRET_MOUNT = '/run/secrets/'


def read_secret(secret):
    with open(os.path.join(SECRET_MOUNT, secret)) as f:
        return f.read().rstrip('\r\n')
