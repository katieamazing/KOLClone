import random
from django.shortcuts import render
from .models import Adventure

# Create your views here.
def damage(request):
    possible_adventures = Adventure.objects.all()
    selected_adv_index = random.randrange(0, len(possible_adventures))
    selected_adv = possible_adventures[selected_adv_index]

    hp = selected_adv.damage()
    name = selected_adv.name

    return render(request, 'advs/damage.json', {'hp': hp, 'name': name})

def index(request):
    return render(request, 'advs/index.html', {})
