# coding: utf-8
# Django core and 3rd party imports
import factory

from .models import User


class UserFactory(factory.django.DjangoModelFactory):
    email = 'bot@vertis.com'

    class Meta:
        model = User
        django_get_or_create = ('email', )
