from django.db import models
from django.utils.translation import gettext_lazy as _


class Feature(models.Model):
    """
    A collection of features presented in the demo app.
    """
    name = models.CharField(max_length=50, verbose_name=_('Name'))
    description = models.TextField(verbose_name=_('Description'))
