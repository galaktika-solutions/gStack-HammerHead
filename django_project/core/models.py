# coding: utf-8
from django.db import models


class KeyValueStore(models.Model):
    '''
    We store here the application settings
    '''
    key = models.CharField(max_length=100, unique=True)
    value = models.CharField(max_length=255, blank=True)

    def __str__(self):
        return self.key

    @staticmethod
    def get_data(key, with_lock=False):
        try:
            qs = KeyValueStore.objects
            if with_lock:
                qs = qs.select_for_update()
            return qs.get(key=key)
        except KeyValueStore.DoesNotExist:
            return KeyValueStore.objects.create(key=key)
