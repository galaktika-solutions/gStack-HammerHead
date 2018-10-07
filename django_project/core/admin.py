# coding: utf-8
# Django core and 3rd party imports
from django.contrib import admin

# Project imports
from .models import KeyValueStore


class KeyValueStoreAdmin(admin.ModelAdmin):
    list_display = ('id', 'key', 'value')
    list_display_links = list_display

admin.site.register(KeyValueStore, KeyValueStoreAdmin)
