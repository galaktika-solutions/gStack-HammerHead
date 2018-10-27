from asgiref.sync import async_to_sync as sync
from channels.generic.websocket import JsonWebsocketConsumer


class Websocket(JsonWebsocketConsumer):
    def connect(self):
        sync(self.channel_layer.group_add)('everybody', self.channel_name)
        self.accept()

    def message(self, event):
        self.send_json(event)
