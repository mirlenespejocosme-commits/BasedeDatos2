import json

with open('datos.json', 'r') as f:
    data = json.load(f)

for unidad in data.get('unidades', []):
    for semana in unidad.get('semanas', []):
        if 'actividades' in semana:
            actividades = semana.pop('actividades')
            semana['carpetas'] = [
                {
                    "nombre": "Trabajos",
                    "actividades": actividades
                }
            ]
        elif 'carpetas' not in semana:
            semana['carpetas'] = []

with open('datos.json', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
