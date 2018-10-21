# coding: utf-8
# Django core and 3rd party imports
from rest_framework.renderers import BrowsableAPIRenderer


class BrowsableAPIRendererWithoutForm(BrowsableAPIRenderer):
    """ Disable the FORM on the BrowsableAPIRenderer. """
    def show_form_for_method(self, view, method, request, obj):
        return False
