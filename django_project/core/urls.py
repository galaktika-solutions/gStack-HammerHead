# coding: utf-8
# Django core and 3rd party imports
from django.urls import path, include
from django.contrib import admin
from django.conf import settings

# Project imports
from .views import KeyValueStoreApiView

api_patterns = [
    # path('^', include(router.urls)),
    path('key_value_store/', KeyValueStoreApiView.as_view()),
]

urlpatterns = [
    path('admin/', admin.site.urls),
    path('explorer/', include('explorer.urls')),
    path('api/', include((api_patterns, 'api'), namespace='api')),
    path('rest-auth/', include('rest_auth.urls')),
]

if settings.DEBUG:
    import debug_toolbar
    urlpatterns = [
        path('__debug__/', include(debug_toolbar.urls)),
    ] + urlpatterns
