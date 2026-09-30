extends Node
## Autoload (singleton) con las señales globales del juego.
## Sirve para que nodos sin referencia directa entre sí puedan comunicarse
## (ej: la UI le avisa a main.gd que hay que spawnear un edificio, o un
## generador le avisa a main.gd que produjo energía).

signal energy_ready
signal water_ready                # se emite cada vez que un generador produce energía
signal food_ready
signal research_ready
signal mineral_ready
signal ground_clicked
signal builidng_placed(building)
signal spawn_building(index: int)  # se emite cuando hay que instanciar un edificio nuevo
