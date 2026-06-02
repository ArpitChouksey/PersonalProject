#!/usr/bin/env python

import os
import sys


def main():

    os.environ.setdefault(
        'DJANGO_SETTINGS_MODULE',
        'python_service.settings'
    )

    print("Starting Django...")

    try:

        import python_service.tracing

        print("Tracing module imported successfully")

        from opentelemetry.instrumentation.django import (
            DjangoInstrumentor
        )

        DjangoInstrumentor().instrument()

        print("OpenTelemetry Django Instrumentation Enabled")

    except Exception as e:

        print("====================================")
        print("OpenTelemetry Initialization Failed")
        print(str(e))
        print("====================================")

        raise

    from django.core.management import (
        execute_from_command_line
    )

    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
