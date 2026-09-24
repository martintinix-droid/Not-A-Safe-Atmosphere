extends Node
## Autoload (singleton) con las señales globales del juego.
## Sirve para que nodos sin referencia directa entre sí puedan comunicarse
## (ej: la UI le avisa a main.gd que hay que spawnear un edificio, o un
## generador le avisa a main.gd que produjo energía).

signal energy_ready                # se emite cada vez que un generador produce energía
signal spawn_building(index: int)  # se emite cuando hay que instanciar un edificio nuevo
