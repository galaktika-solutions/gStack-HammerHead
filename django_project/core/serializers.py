# coding: utf-8
# Django core and 3rd party imports
from rest_framework.serializers import ModelSerializer

# MV2 imports
from .models import KeyValueStore


class KeyValueStoreSerializer(ModelSerializer):
    class Meta:
        model = KeyValueStore
        fields = ('id', 'key', 'value')
