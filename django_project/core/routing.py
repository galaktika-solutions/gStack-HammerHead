# Django core and 3rd party imports
from django.urls import path
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack

# MV2 imports
from . import consumers

application = ProtocolTypeRouter({
    # (http->django views is added by default)
    'websocket': AuthMiddlewareStack(
        URLRouter(
            [
                path('ws', consumers.Websocket),
            ]
        )
    ),
})
