extends Node
## Autoload con referencias globales a nodos clave de la escena.
## main.gd se registra acá en su _ready().
##
## NOTA: por ahora nadie más lee main_ref. Si no lo vas a usar, se puede
## borrar este script junto con su entrada en Project Settings > Autoload.

var main_ref: Node
