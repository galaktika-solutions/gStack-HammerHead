from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class Config(AppConfig):
    name = 'demo'
    verbose_name = _('gStack Features Demo')
