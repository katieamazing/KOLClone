# -*- coding: utf-8 -*-
# Generated by Django 1.10.6 on 2017-03-29 18:44
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('advs', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='adventure',
            name='location',
            field=models.CharField(default='default location', max_length=200),
            preserve_default=False,
        ),
    ]
