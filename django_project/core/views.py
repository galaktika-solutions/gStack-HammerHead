# coding: utf-8
# Django core and 3rd party imports
from rest_framework.viewsets import ModelViewSet

# Project imports
from .models import KeyValueStore
from .serializers import KeyValueStoreSerializer
from .mixins import NoJsonPaginationMixin


class KeyValueStoreViewset(NoJsonPaginationMixin, ModelViewSet):
    """ Contains Technical informations. """
    serializer_class = KeyValueStoreSerializer
    queryset = KeyValueStore.objects.all()
    filter_fields = ('key', )
