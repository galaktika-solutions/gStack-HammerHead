# coding: utf-8
# Django core and 3rd party imports
import os
from django.core.mail.backends.smtp import EmailBackend as Backend


class EmailBackend(Backend):
    def send_messages(self, email_messages):
        rewrite = os.environ.get('REWRITE_RECIPIENTS')
        if rewrite:
            for msg in email_messages:
                msg.to = [rewrite]
                msg.cc = []
                msg.bcc = []
        return super().send_messages(email_messages)
