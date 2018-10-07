# coding: utf-8
# Django core and 3rd party imports
from rest_framework.response import Response
from rest_framework.views import APIView

# Project imports
from .models import KeyValueStore


class KeyValueStoreApiView(APIView):
    """
    This api contains technical informations anybody can see
    """
    def get(self, request, format=None):
        obj = KeyValueStore.objects.get(key=request.GET.get('key'))
        return Response({'key': obj.key, 'value': obj.value})
