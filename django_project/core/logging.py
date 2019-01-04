import logging


class GStackFormatter(logging.Formatter):
    """
    Prepends exception logs with a `-` sign to help log parsers keep
    log records together.
    """
    def formatException(self, *args, **kwargs):
        ex = super().formatException(*args, **kwargs)
        return ''.join(['- ' + l for l in ex.splitlines(True)])
