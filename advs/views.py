import random
import json
from django.shortcuts import render
from .models import Adventure

# Create your views here.
def damage(request):
    # TODO parse json, but like, better
    body_unicode = request.body.decode('utf-8')
    data = json.loads(body_unicode)
    location = str(data["current_loc"])

    possible_adventures = Adventure.objects.filter(location=location)

    selected_adv_index = random.randrange(0, len(possible_adventures))
    selected_adv = possible_adventures[selected_adv_index]

    hp = selected_adv.damage()
    name = selected_adv.name
    location = selected_adv.location

    return render(request, 'advs/damage.json', {'hp': hp, 'name': name, 'location': location})


def get_monster(request):
    body_unicode = request.body.decode('utf-8')
    data = json.loads(body_unicode)
    location = str(data["current_loc"])

    possible_adventures = Adventure.objects.filter(location=location)

    selected_adv_index = random.randrange(0, len(possible_adventures))
    selected_adv = possible_adventures[selected_adv_index]

    name = selected_adv.name

    return render(request, 'advs/get_monster.json', {'name': name})


def turn_damage(request):
    body_unicode = request.body.decode('utf-8')
    data = json.loads(body_unicode)
    name = str(data["name"])

    monsters = Adventure.objects.filter(name=name)
    if len(monsters) == 0:
        return HttpResponse(status=500)
    else:
        monster = monsters[0]
        damage = monster.damage()
        return render(request, 'advs/turn_damage.json', {'damage': damage})


def index(request):
    return render(request, 'advs/index.html', {})
