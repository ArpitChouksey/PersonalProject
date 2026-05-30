from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-insecure-change-this'

DEBUG = True

ALLOWED_HOSTS = ['*']


# ===============================
# INSTALLED APPS
# ===============================

INSTALLED_APPS = [

    'django_prometheus',

    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    'api',
]


# ===============================
# MIDDLEWARE
# ===============================

MIDDLEWARE = [

    'django_prometheus.middleware.PrometheusBeforeMiddleware',

    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',

    'django_prometheus.middleware.PrometheusAfterMiddleware',
]


ROOT_URLCONF = 'python_service.urls'

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

WSGI_APPLICATION = 'python_service.wsgi.application'


# ===============================
# DATABASE
# ===============================

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}


# ===============================
# PASSWORD VALIDATION
# ===============================

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# ===============================
# INTERNATIONALIZATION
# ===============================

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# ===============================
# STATIC FILES
# ===============================

STATIC_URL = 'static/'


# ===============================
# DEFAULT PRIMARY KEY
# ===============================

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


# ===============================
# LOGGING (JSON STRUCTURED LOGS)
# ===============================

LOGGING = {

    "version": 1,

    "disable_existing_loggers": False,

    "formatters": {

        "json": {

            "()": "pythonjsonlogger.jsonlogger.JsonFormatter",

            "format":
                "%(asctime)s %(levelname)s %(name)s %(message)s"
        }
    },

    "handlers": {

        "console": {

            "class": "logging.StreamHandler",

            "formatter": "json"
        }
    },

    "root": {

        "handlers": ["console"],

        "level": "INFO"
    }
}
