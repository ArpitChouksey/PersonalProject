from django.urls import path
from .views import hello, create_user

urlpatterns = [
    path('hello/<str:name>', hello),
    path('users', create_user),
]

