from django.conf.urls import url
from . import views

urlpatterns = [
    url(r'^$', views.damage, name='damage'),
    url(r'^index.html$', views.index, name='index')
]
