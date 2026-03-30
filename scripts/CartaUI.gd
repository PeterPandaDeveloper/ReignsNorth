extends Control

# --- VARIABLES DE NODOS VISUALES ---
# (Estas variables están comentadas con # porque en VS Code aún no existen los nodos gráficos. 
# Cuando abras Godot, le quitaremos el # para conectarlos).

# @onready var ui_personaje = $Panel/NombrePersonaje
# @onready var ui_texto = $Panel/TextoCarta
# @onready var btn_izq = $HBoxContainer/BotonIzquierda
# @onready var btn_der = $HBoxContainer/BotonDerecha

var carta_actual: Dictionary = {}

# --- POOL DE NOMBRES ALEATORIOS ---
var nombres_aleatorios = {
	"Campesina": [
		"Campesina María", "Campesina Elara", "Campesina Nora", 
		"Campesina Lía", "Campesina Greta", "Campesina Marta"
	],
	"Caballero": [
		"Caballero Tristán", "Caballero Godric", "Caballero Aldous", 
		"Caballero Vane", "Caballero Kael", "Caballero Cedric"
	],
	"Mercader": [
		"Mercader Samir", "Mercader Volo", "Mercader Jafar", 
		"Mercader Tariq", "Mercader Omar", "Mercader Hakim"
	],
	"Lord Feudal bueno": [
		"Lord Alistair (El Justo)", "Lord Rowan (El Fiel)", 
		"Lord Edmund (El Próspero)", "Lord Arthur (El Noble)"
	],
	"Lord Feudal malo": [
		"Lord Vane (El Pantanoso)", "Lord Blackwood (El Avaro)", 
		"Lord Malakor (El Cruel)", "Lord Draven (El Sombrío)"
	]
}

func _ready():
	# Cuando pases a Godot, conectaremos los botones así:
	# btn_izq.pressed.connect(_on_btn_izq_pressed)
	# btn_der.pressed.connect(_on_btn_der_pressed)
	
	# Le damos un instante al GameManager para que cargue el JSON antes de pedir cartas
	await get_tree().create_timer(0.1).timeout
	siguiente_turno()

func siguiente_turno():
	carta_actual = GameManager.obtener_siguiente_carta()
	actualizar_pantalla()

func actualizar_pantalla():
	var nombre_mostrar = carta_actual["personaje"]
	
	# Lógica: Si el personaje es genérico, elige un nombre al azar de la pool
	if nombres_aleatorios.has(nombre_mostrar):
		nombre_mostrar = nombres_aleatorios[nombre_mostrar].pick_random()
		
	# Actualizamos la pantalla (Comentado para que no dé error sin Godot abierto)
	# ui_personaje.text = nombre_mostrar
	# ui_texto.text = carta_actual["texto"]
	# btn_izq.text = carta_actual["opcion_1"]["texto"]
	# btn_der.text = carta_actual["opcion_2"]["texto"]
	
	# Esto imprimirá la carta en la terminal de tu AntiX para que puedas leerla
	print("\n--- AÑO: ", GameManager.turno_actual / 12, " | MES: ", GameManager.turno_actual, " ---")
	print("Poderes -> E:", GameManager.ejercito, " | T:", GameManager.tesoro, " | P:", GameManager.pueblo, " | C:", GameManager.consejo)
	print("HABLA ", nombre_mostrar, ": ", carta_actual["texto"])
	print("[1] ", carta_actual["opcion_1"]["texto"], "   |   [2] ", carta_actual["opcion_2"]["texto"])

# Estas funciones se llamarán cuando el jugador haga clic
func _on_btn_izq_pressed():
	GameManager.aplicar_decision(carta_actual["opcion_1"])
	siguiente_turno()

func _on_btn_der_pressed():
	GameManager.aplicar_decision(carta_actual["opcion_2"])
	siguiente_turno()

# FUNCIÓN PARA PROBAR EN CONSOLA (Sin gráficos)
# Borraremos esto cuando estemos en Godot
func simular_click_en_consola(eleccion: int):
	if eleccion == 1:
		_on_btn_izq_pressed()
	elif eleccion == 2:
		_on_btn_der_pressed()

# --- CONTROLES POR TECLADO ---
func _process(delta):
    # Detecta si presionas A o Flecha Izquierda
    if Input.is_action_just_pressed("ui_left"):
        _on_btn_izq_pressed()
    # Detecta si presionas D o Flecha Derecha
    elif Input.is_action_just_pressed("ui_right"):
        _on_btn_der_pressed()