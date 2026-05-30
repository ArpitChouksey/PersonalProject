"""
URL configuration for python_service project.

The `urlpatterns` list routes URLs to views.
"""

from django.contrib import admin
from django.urls import path, include

urlpatterns = [

    path('admin/', admin.site.urls),

    # Existing API routes
    path('', include('api.urls')),

    # Prometheus metrics endpoint
    path('', include('django_prometheus.urls')),
]
