import os

from gdockutils import read_secret_from_file


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SECRET_KEY = read_secret_from_file('DJANGO_SECRET_KEY')

DEBUG = os.environ.get('ENV') == 'DEV'

ALLOWED_HOSTS = [os.environ.get('HOST_NAME'), os.environ.get('SERVER_IP')]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'demo.apps.Config',
]

if DEBUG:
    INSTALLED_APPS.append('debug_toolbar')
    MIDDLEWARE.append(
        'debug_toolbar.middleware.DebugToolbarMiddleware'
    )
    DEBUG_TOOLBAR_CONFIG = {
        'SHOW_TOOLBAR_CALLBACK': lambda x: DEBUG
    }

ROOT_URLCONF = 'core.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'core.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'HOST': 'postgres',
        'PORT': '5432',
        'NAME': 'django',
        'USER': 'django',
        'PASSWORD': read_secret_from_file('DB_PASSWORD_DJANGO'),
        'OPTIONS': {
            'sslmode': 'verify-ca',
            'sslrootcert': '/run/secrets/PG_SERVER_SSL_CACERT',
            'sslcert': '/run/secrets/PG_CLIENT_SSL_CERT',
            'sslkey': '/run/secrets/PG_CLIENT_SSL_KEY',

        },
    },
}

validators = [
    'UserAttributeSimilarityValidator', 'MinimumLengthValidator',
    'CommonPasswordValidator', 'NumericPasswordValidator'
]
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.%s' % v}
    for v in validators
]

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_L10N = True
DATE_FORMAT = ('Y-m-d')
DATETIME_FORMAT = ('Y-m-d H:i:s')
TIME_FORMAT = ('H:i:s')

USE_TZ = True

STATIC_URL = '/assets/'
STATIC_ROOT = '/src/static/'

# File Upload max 50MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 52428800
FILE_UPLOAD_MAX_MEMORY_SIZE = 52428800
FILE_UPLOAD_DIRECTORY_PERMISSIONS = 0o750
FILE_UPLOAD_PERMISSIONS = 0o640

SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
