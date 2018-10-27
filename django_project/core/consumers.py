# coding: utf-8
# Django core and 3rd party imports
from asgiref.sync import async_to_sync
from channels.generic.websocket import JsonWebsocketConsumer


class Websocket(JsonWebsocketConsumer):
    def connect(self):
        async_to_sync(self.channel_layer.group_add)(
            'everybody',
            self.channel_name
        )
        self.accept()

    def message(self, event):
        self.send_json(event)
