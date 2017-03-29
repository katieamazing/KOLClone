from django.db import models
import random

# Create your models here.

class Adventure(models.Model):
    hp_range_start = models.IntegerField()
    level = models.IntegerField()
    name = models.CharField(max_length=200)
    location = models.CharField(max_length=200)

    def __str__(self):
        return self.name

    def damage(self):
        return random.randrange(self.hp_range_start, self.hp_range_start + self.level)
