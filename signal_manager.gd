extends Node
## Autoload (singleton) holding the game's global signals.
## Lets nodes that have no direct reference to each other communicate
## (e.g. the UI asks main.gd to spawn a building, or main.gd tells the base
## that something was clicked).


# --- Input ---

## Free ground was clicked (there was no interactable under the cursor).
signal ground_clicked(click_position: Vector2)

## An interactable was clicked. Emitted AFTER the interactable's own
## "clicked" signal. The base decides whether to send a rover
## (see base.gd / outpost_rover.gd).
signal interactable_clicked(target: Node)

## The inventory key was pressed. Emitted by main.gd; ui.gd listens to it and
## slides the inventory panel in or out.
signal inventory_actioned


# --- Construction ---

## The UI asks main.gd to spawn a building. building_id is a key of
## Buildings.DATA (see Buildings.gd).
signal spawn_building(building_id: String)
