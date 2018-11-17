from django.test import TestCase
from django.conf import settings
import django

from gdockutils import read_secret_from_file


class SimpreTestCase(TestCase):
    maxDiff = None

    def test_read_secret(self):
        django.setup()
        self.assertEqual(
            settings.SECRET_KEY,
            read_secret_from_file('DJANGO_SECRET_KEY')
        )
