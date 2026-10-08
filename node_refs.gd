extends Node
## Autoload with global references to key scene nodes.
## main.gd registers itself here in its _ready().
##
## NOTE: nothing else reads main_ref yet. If it ends up unused, this script
## can be deleted along with its entry in Project Settings > Autoload.

var main_ref: Node
