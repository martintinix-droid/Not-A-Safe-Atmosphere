extends Node
## Autoload (singleton) con las señales globales del juego.
## Sirve para que nodos sin referencia directa entre sí puedan comunicarse
## (ej: la UI le pide a main.gd que instancie un edificio, o main.gd le avisa
## a la base que algo fue clickeado).

# --- Recursos ---
## Un generador produjo una unidad del recurso correspondiente.
signal energy_ready
signal water_ready
## Reservadas para recursos futuros (todavía nadie las emite ni las escucha).
signal food_ready
signal research_ready
signal mineral_ready

# --- Input ---
## Se clickeó terreno libre (no había ningún interactuable bajo el click).
signal ground_clicked(click_position: Vector2)
## Se clickeó un interactuable. Se emite DESPUÉS de su propia señal "clicked".
## La base decide si le manda un rover (ver base.gd / outpost_rover.gd).
signal interactable_clicked(target: Node)

# --- Construcción ---
## La UI pide instanciar un edificio. building_id es una clave de BUILDINGS (main.gd).
signal spawn_building(building_id: String)
