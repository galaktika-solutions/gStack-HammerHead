# coding: utf-8
# Django core and 3rd party imports
from rest_framework.viewsets import ModelViewSet
from django.http import HttpResponse
from django.views import View
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

# Project imports
from .models import KeyValueStore
from .serializers import KeyValueStoreSerializer
from .mixins import NoJsonPaginationMixin


class KeyValueStoreViewset(NoJsonPaginationMixin, ModelViewSet):
    """ Contains Technical informations. """
    serializer_class = KeyValueStoreSerializer
    queryset = KeyValueStore.objects.all()
    filter_fields = ('key', )


class DjangoChannelsTestView(View):
    def get(self, request):
        async_to_sync(get_channel_layer().group_send)(
            'everybody', {
                'type': 'message',
                'topic': 'test',
                'data': 'Hello everybody.'
            }
        )
        return HttpResponse('Message was sent to everybody.')
