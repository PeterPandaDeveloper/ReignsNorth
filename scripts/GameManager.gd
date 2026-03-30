extends Node

# --- 1. ESTADÍSTICAS DEL REINO ---
# Empiezan a la mitad. Si llegan a 0 o a 100, el rey muere.
var ejercito: int = 50
var tesoro: int = 50
var pueblo: int = 50
var consejo: int = 50

# --- 2. TIEMPO Y LÍMITES ---
var turno_actual: int = 0
var LIMITE_TURNOS: int = 120 # 120 cartas = 10 años exactos de gobierno.

# --- 3. BANDERAS DE LA HISTORIA ---
var tutorial_visto: bool = false
var carta_forzada: String = "" # Si tiene texto, saca esa carta obligatoriamente

# Supervivencia del Consejo
var anyara_viva: bool = true
var silas_vivo: bool = true
var kaelon_vivo: bool = true
var lleah_vivo: bool = true

# Progresión de Arcos y Finales
var arcos_completados: int = 0
var discipulos_castigados: int = 0
var acro_vistos: int = 0 # Cuenta cuántos reportes trimestrales has sobrevivido

# --- 4. BASE DE DATOS ---
var mazo_datos: Dictionary = {}

func _ready():
	randomize() # Asegura que la suerte sea realmente aleatoria cada partida
	cargar_mazo_json()

func cargar_mazo_json():
	var file = FileAccess.open("res://data/mazo.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			mazo_datos = json.data
			print("✅ Mazo cargado. El cerebro de North está en línea.")
		else:
			print("❌ Error crítico en el JSON. Revisa tus comas.")
	else:
		print("❌ No se encontró el archivo mazo.json")

# --- 5. EL MOTOR DE DECISIONES ---
func aplicar_decision(opcion: Dictionary):
	var efecto_final = {}

	# A. ¿Hay factor suerte en esta decisión? (60% / 40%, etc.)
	if opcion.has("prob_exito"):
		var tirada = randi() % 100 + 1 # Tira un dado del 1 al 100
		if tirada <= opcion["prob_exito"]:
			efecto_final = opcion.get("efecto_exito", {})
			print("¡Éxito en la probabilidad!")
		else:
			efecto_final = opcion.get("efecto_fracaso", {})
			print("Fracaso en la probabilidad...")
	else:
		# Si no hay suerte, el efecto es directo
		efecto_final = opcion.get("efecto", {})

	# B. Aplicar sumas y restas (clamp evita que pasen de 100 o bajen de 0)
	ejercito = clamp(ejercito + efecto_final.get("e", 0), 0, 100)
	tesoro = clamp(tesoro + efecto_final.get("t", 0), 0, 100)
	pueblo = clamp(pueblo + efecto_final.get("p", 0), 0, 100)
	consejo = clamp(consejo + efecto_final.get("c", 0), 0, 100)

	# C. ¿Hay una acción oculta en el efecto? (Ej. matar a alguien, sumar arcos)
	if efecto_final.has("accion"):
		ejecutar_accion_especial(efecto_final["accion"])

	# D. ¿Hay una carta en cadena? (Minijuegos de visitas, finales)
	if opcion.has("siguiente_carta"):
		carta_forzada = opcion["siguiente_carta"]

	# E. Avanzar el tiempo (si ya pasamos el tutorial)
	if tutorial_visto and carta_forzada == "":
		turno_actual += 1

	# F. Revisar si perdimos o ganamos antes de dar la siguiente carta
	revisar_estado_juego()

# --- 6. EL SISTEMA DE PRIORIDADES (¿Qué carta sigue?) ---
func obtener_siguiente_carta() -> Dictionary:
	
	# Prioridad 1: ¿Estamos en el tutorial?
	if not tutorial_visto and mazo_datos.has("tutorial") and mazo_datos["tutorial"].size() > 0:
		return mazo_datos["tutorial"].pop_front() # Saca la primera y la borra de la lista
		
	# Prioridad 2: ¿Hay una carta forzada en cadena?
	if carta_forzada != "":
		var id_buscar = carta_forzada
		carta_forzada = "" # Limpiamos para que no se cicle infinitamente
		return buscar_carta_por_id(id_buscar)
		
	# Prioridad 3: ¿Reporte trimestral de Acro? (Aparece cada 15 turnos)
	if turno_actual > 0 and turno_actual % 15 == 0:
		if mazo_datos.has("eventos_acro") and mazo_datos["eventos_acro"].size() > 0:
			acro_vistos += 1
			# Elegimos una al azar y la borramos para que Acro no repita reportes
			var indice = randi() % mazo_datos["eventos_acro"].size()
			var carta_acro = mazo_datos["eventos_acro"][indice]
			mazo_datos["eventos_acro"].remove_at(indice)
			return carta_acro

	# Prioridad 4: La vida diaria (Barajamos todas las pools disponibles)
	var pool_cartas = []
	pool_cartas.append_array(mazo_datos["eventos_genericos"])
	pool_cartas.append_array(mazo_datos["eventos_aves"])
	pool_cartas.append_array(mazo_datos["eventos_consejo"])
	# Aquí podrías filtrar si Silas está muerto para no meter sus cartas, etc.
	
	return pool_cartas.pick_random()

# --- 7. BÚSQUEDA Y ACCIONES ESPECIALES ---
func buscar_carta_por_id(id_buscado: String) -> Dictionary:
    for categoria in mazo_datos.values():  # <-- AQUI ESTÁ EL CAMBIO (in en lugar de en)
        for carta in categoria:
            if carta.has("id") and carta["id"] == id_buscado:
                return carta
    print("⚠️ CARTA NO ENCONTRADA: ", id_buscado)
    return mazo_datos["eventos_genericos"][0] # Salvavidas anti-crasheo

func ejecutar_accion_especial(accion: String):
	match accion:
		"saltar_tutorial", "continuar":
			tutorial_visto = true
		"muere_anyara": anyara_viva = false
		"muere_silas": silas_vivo = false
		"muere_kaelon": kaelon_vivo = false
		"muere_lleah": lleah_vivo = false
		"completar_arco_garret", "completar_arco_hans", "completar_arco_jim", "completar_arco_fred":
			arcos_completados += 1
		"castigar_discipulo":
			discipulos_castigados += 1
		"activar_final_falso":
			carta_forzada = "fin_fal_1"
		
		# Lógica de probabilidad para las resoluciones de Desastres (70% Exito / 30% Fracaso)
		"activar_resolucion_anyara":
			carta_forzada = "res_anyara_exito" if randi() % 100 < 70 else "res_anyara_fracaso"
		"activar_resolucion_silas":
			carta_forzada = "res_silas_exito" if randi() % 100 < 70 else "res_silas_fracaso"
		"activar_resolucion_kaelon":
			carta_forzada = "res_kaelon_exito" if randi() % 100 < 70 else "res_kaelon_fracaso"
		"activar_resolucion_lleah":
			carta_forzada = "res_lleah_exito" if randi() % 100 < 70 else "res_lleah_fracaso"
			
		"game_over_falso", "game_over_lucas", "game_over_vacio", "victoria_verdadera":
			print("EL JUEGO HA TERMINADO. Pantalla de créditos...")
			# Aquí luego reiniciaremos la escena

func revisar_estado_juego():
	# ¿Nos quedamos sin tiempo?
	if turno_actual >= LIMITE_TURNOS and carta_forzada == "":
		carta_forzada = "fin_vacio"
		return

	# ¿Activamos el final de Lucas por ser crueles?
	if discipulos_castigados >= 3 and carta_forzada == "":
		carta_forzada = "fin_luc_1"
		return

	# ¿Activamos el Final Verdadero por ser geniales?
	if arcos_completados >= 4 and acro_vistos >= 3 and carta_forzada == "":
		carta_forzada = "fin_ver_1"
		return

	# ¿Nos derrocaron por mal manejo de estadísticas?
	if ejercito <= 0 or tesoro <= 0 or pueblo <= 0 or consejo <= 0:
		print("GAME OVER - Una facción te abandonó por falta de recursos.")
	elif ejercito >= 100 or tesoro >= 100 or pueblo >= 100 or consejo >= 100:
		print("GAME OVER - Una facción se hizo demasiado poderosa y te decapitó.")