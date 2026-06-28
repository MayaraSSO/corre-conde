extends Node

# ===========================================================================
# DadosJogo.gd — Singleton Global (Autoload)
# Persiste dados entre cenas: fase atual, vida, itens coletados, etc.
# ===========================================================================

# Estado do jogo
var fase_atual = 1
var total_fases = 3
var energia_vital = 100.0
var pedacos_coletados = 0
var total_pedacos = 3
var vidas_restantes = 3

# Modo de jogo
var modo_editor = false
var caminho_fase_custom = ""  # Caminho para .lvl carregado pelo editor

# Configurações
var volume_musica = 0.8
var volume_efeitos = 1.0

# Registro de fases completadas
var fases_completadas = []

# Flags para controle do Tutorial (Fase 1)
var tutorial_ativo = true
var tutor_movimento_exibido = false
var tutor_cruz_exibido = false
var tutor_combate_exibido = false
var tutor_sol_exibido = false
var tutor_anel_exibido = false
var tutor_paladino_exibido = false

func _ready():
	print("DadosJogo: Singleton inicializado.")
	# Registra dinamicamente a tecla 'Z' para ação de Parry (Capa de Hipnose)
	if not InputMap.has_action("combate_parry"):
		InputMap.add_action("combate_parry")
		var ev_z = InputEventKey.new()
		ev_z.scancode = KEY_Z
		InputMap.action_add_event("combate_parry", ev_z)
		var ev_c = InputEventKey.new()
		ev_c.scancode = KEY_C
		InputMap.action_add_event("combate_parry", ev_c)
		print("DadosJogo: Mapeamento das teclas Z e C para combate_parry registrado com sucesso.")
	
	# Registra a tecla Espaço para ação de Espada (ataque aos lobos)
	if not InputMap.has_action("combate_espada"):
		InputMap.add_action("combate_espada")
		var ev_espada = InputEventKey.new()
		ev_espada.scancode = KEY_SPACE
		InputMap.action_add_event("combate_espada", ev_espada)
		print("DadosJogo: Mapeamento da tecla ESPAÇO para combate_espada registrado com sucesso.")

func resetar_para_nova_partida():
	fase_atual = 1
	energia_vital = 100.0
	pedacos_coletados = 0
	vidas_restantes = 3
	fases_completadas = []
	modo_editor = false
	caminho_fase_custom = ""
	tutor_movimento_exibido = false
	tutor_cruz_exibido = false
	tutor_combate_exibido = false
	tutor_sol_exibido = false
	tutor_anel_exibido = false
	tutor_paladino_exibido = false

func avancar_fase():
	fases_completadas.append(fase_atual)
	fase_atual += 1
	energia_vital = 100.0  # Restaura vida entre fases
	pedacos_coletados = 0

func fase_completada(num_fase: int) -> bool:
	return num_fase in fases_completadas

func obter_caminho_lvl(num_fase: int) -> String:
	"""Retorna o caminho do arquivo .lvl para uma fase."""
	if modo_editor and caminho_fase_custom != "":
		return caminho_fase_custom
	return "res://levels/" + str(num_fase) + ".lvl"
