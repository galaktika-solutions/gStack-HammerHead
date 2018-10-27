# coding: utf-8
# Django core and 3rd party imports
from django.urls import path, include
from django.contrib import admin
from django.conf import settings
from rest_framework.routers import SimpleRouter

# Project imports
from .views import KeyValueStoreViewset, DjangoChannelsTestView
from .routers import ContainerRouter

# core viewsets
SharedRouter = SimpleRouter()
SharedRouter.register(
    r'key_value_store',
    KeyValueStoreViewset,
    base_name='key_value_store'
)

# Register every other application SharedRouter in here
# Example:
# from pydoc import locate
# router.register_router(locate('other.urls.SharedRouter'))
router = ContainerRouter()
router.register_router(SharedRouter)

api_patterns = [
    path('', include(router.urls)),
]

urlpatterns = [
    path('admin/', admin.site.urls),
    path('explorer/', include('explorer.urls')),
    path('api/', include((api_patterns, 'api'), namespace='api')),
    path('rest-auth/', include('rest_auth.urls')),
    path('django-channels/test/', DjangoChannelsTestView.as_view())
]

if settings.DEBUG:
    import debug_toolbar
    urlpatterns = [
        path('__debug__/', include(debug_toolbar.urls)),
    ] + urlpatterns
