# coding: utf-8
# Django core and 3rd party imports
from django.conf import settings


class NoJsonPaginationMixin(object):
    def list(self, request, *args, **kwargs):
        size = request.GET.get(settings.REST_FRAMEWORK['PAGINATE_BY_PARAM'])
        if request.accepted_media_type != 'text/html' and size is None:
            self.paginate_queryset = lambda x: None
        return super(NoJsonPaginationMixin, self).list(
            request, *args, **kwargs)
