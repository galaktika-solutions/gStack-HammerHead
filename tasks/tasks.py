#!/usr/bin/env python3

import signal
import logging
import sys
import os

from periodtask import TaskList, Task, SKIP

import django
django.setup()


stdout = logging.StreamHandler(sys.stdout)
fmt = logging.Formatter('%(levelname)s|%(name)s|%(asctime)s|%(message)s')
stdout.setFormatter(fmt)
root = logging.getLogger()
root.addHandler(stdout)
root.setLevel(logging.INFO)


tasklist = []

if os.environ.get('SEND_MAIL_TASK') == 'True':
    tasklist.append(
        Task(
            name='send_mail',
            command=('django-admin', 'send_mail'),
            periods='*/5 *',
            wait_timeout=5,
            stop_signal=signal.SIGINT,
            policy=SKIP,
            stdout_level=logging.DEBUG,
            stderr_level=logging.DEBUG,
        )
    )

if os.environ.get('RETRY_DEFERRED_TASK') == 'True':
    tasklist.append(
        Task(
            name='retry_deferred',
            command=('django-admin', 'retry_deferred'),
            periods='10 *',
            wait_timeout=5,
            stop_signal=signal.SIGINT,
            policy=SKIP,
            stdout_level=logging.DEBUG,
            stderr_level=logging.DEBUG,
        )
    )

TaskList(*tasklist).start()
