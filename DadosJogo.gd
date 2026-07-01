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

# ===========================================================================
# SISTEMA DE CRONÔMETRO E RANKING
# ===========================================================================
var tempo_fase_atual : float = 0.0
var tempos_fases = {1: 0.0, 2: 0.0, 3: 0.0}
var cronometro_ativo : bool = false
var ranking_dados = []  # Array de dicionários com os recordes

# Flags para controle do Tutorial (Fase 1)
var tutorial_ativo = true
var tutor_movimento_exibido = false
var tutor_cruz_exibido = false
var tutor_combate_exibido = false
var tutor_sol_exibido = false
var tutor_anel_exibido = false
var tutor_paladino_exibido = false
var tutor_arvore_exibido = false
var tutor_ranking_exibido = false
var tutor_paladino_fase2_exibido = false
var tutor_caixao_exibido = false
var tutor_paladino_fase3_exibido = false

func _ready():
	print("DadosJogo: Singleton inicializado.")
	# Carrega o ranking persistido
	carregar_ranking()
	
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
		
	# Registra a tecla Shift para ação de Correr
	if not InputMap.has_action("correr"):
		InputMap.add_action("correr")
		var ev_shift = InputEventKey.new()
		ev_shift.scancode = KEY_SHIFT
		InputMap.action_add_event("correr", ev_shift)
		print("DadosJogo: Mapeamento da tecla SHIFT para correr registrado com sucesso.")

func _process(delta):
	# Incrementa o cronômetro quando ativo e o jogo não está pausado
	if cronometro_ativo:
		tempo_fase_atual += delta

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
	tutor_arvore_exibido = false
	tutor_ranking_exibido = false
	tutor_paladino_fase2_exibido = false
	tutor_caixao_exibido = false
	tutor_paladino_fase3_exibido = false
	# Reseta cronômetro e tempos de todas as fases
	tempo_fase_atual = 0.0
	tempos_fases = {1: 0.0, 2: 0.0, 3: 0.0}
	cronometro_ativo = false

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

# ===========================================================================
# FUNÇÕES DO CRONÔMETRO
# ===========================================================================

func resetar_tempo_fase_atual():
	"""Reseta o cronômetro para o início de uma nova fase."""
	tempo_fase_atual = 0.0
	cronometro_ativo = false
	print("[DadosJogo] Cronômetro resetado para a fase ", fase_atual)

func salvar_tempo_fase_atual():
	"""Salva o tempo acumulado da fase atual no dicionário de tempos."""
	tempos_fases[fase_atual] = tempo_fase_atual
	cronometro_ativo = false
	print("[DadosJogo] Tempo da Fase ", fase_atual, " salvo: ", formatar_tempo(tempo_fase_atual))

func obter_tempo_total() -> float:
	"""Retorna a soma dos tempos de todas as fases."""
	return tempos_fases[1] + tempos_fases[2] + tempos_fases[3]

func obter_tempo_geral_atual() -> float:
	"""Retorna o tempo acumulado da partida atual (fases passadas + tempo da fase atual)."""
	var total_acumulado = 0.0
	for i in range(1, fase_atual):
		total_acumulado += tempos_fases[i]
	return total_acumulado + tempo_fase_atual

func formatar_tempo(tempo_segundos: float) -> String:
	"""Formata um tempo em segundos para a string MM:SS.CC"""
	var minutos = int(tempo_segundos) / 60
	var segundos = int(tempo_segundos) % 60
	var centesimos = int((tempo_segundos - int(tempo_segundos)) * 100)
	return "%02d:%02d.%02d" % [minutos, segundos, centesimos]

# ===========================================================================
# FUNÇÕES DE PERSISTÊNCIA DO RANKING (user://ranking.json)
# ===========================================================================

func carregar_ranking():
	"""Carrega o ranking do arquivo JSON persistido."""
	var arquivo = File.new()
	if arquivo.file_exists("user://ranking.json"):
		var erro = arquivo.open("user://ranking.json", File.READ)
		if erro == OK:
			var texto = arquivo.get_as_text()
			arquivo.close()
			var resultado = JSON.parse(texto)
			if resultado.error == OK and resultado.result is Dictionary:
				ranking_dados = resultado.result.get("ranking", [])
				print("[DadosJogo] Ranking carregado com ", ranking_dados.size(), " registros.")
			else:
				ranking_dados = []
				print("[DadosJogo] Erro ao parsear ranking.json, reinicializando.")
		else:
			ranking_dados = []
	else:
		ranking_dados = []
		print("[DadosJogo] Nenhum ranking encontrado, iniciando vazio.")

func salvar_ranking():
	"""Salva o ranking atual no arquivo JSON."""
	var arquivo = File.new()
	var erro = arquivo.open("user://ranking.json", File.WRITE)
	if erro == OK:
		var dados = {"ranking": ranking_dados}
		arquivo.store_string(JSON.print(dados, "\t"))
		arquivo.close()
		print("[DadosJogo] Ranking salvo com ", ranking_dados.size(), " registros.")

func adicionar_recorde(nome_jogador: String):
	"""Adiciona um novo recorde ao ranking com os tempos atuais."""
	# Monta a data atual
	var dt = OS.get_datetime()
	var data_str = "%02d/%02d/%04d" % [dt["day"], dt["month"], dt["year"]]
	
	var registro = {
		"nome": nome_jogador.to_upper().strip_edges(),
		"tempo_total": obter_tempo_total(),
		"tempo_fase1": tempos_fases[1],
		"tempo_fase2": tempos_fases[2],
		"tempo_fase3": tempos_fases[3],
		"data": data_str
	}
	
	ranking_dados.append(registro)
	
	# Ordena por tempo_total (menor primeiro = melhor)
	ranking_dados.sort_custom(self, "_comparar_ranking")
	
	# Limita a 10 melhores
	if ranking_dados.size() > 10:
		ranking_dados.resize(10)
	
	salvar_ranking()
	print("[DadosJogo] Recorde adicionado: ", nome_jogador, " - ", formatar_tempo(obter_tempo_total()))

func _comparar_ranking(a, b) -> bool:
	"""Comparador para ordenar ranking por tempo total crescente."""
	return a["tempo_total"] < b["tempo_total"]

