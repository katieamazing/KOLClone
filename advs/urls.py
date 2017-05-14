from django.conf.urls import url
from . import views

urlpatterns = [
    url(r'^$', views.damage, name='damage'),
    url(r'^get_monster$', views.get_monster, name='name'),
    url(r'^turn_damage$', views.turn_damage, name='damage'),
    url(r'^index.html$', views.index, name='index')
]
