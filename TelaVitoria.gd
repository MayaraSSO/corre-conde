extends Control

# ===========================================================================
# TelaVitoria.gd — Tela de vitória com exibição de tempos e salvamento no ranking
# ===========================================================================

var campo_nome : LineEdit = null
var botao_salvar : Button = null
var label_status : Label = null
var ja_salvou = false

func _ready():
	# Constrói a interface de tempos e ranking dinamicamente
	_construir_interface_tempos()
	
	# Toca o som de vitória em loop
	var player_vitoria = AudioStreamPlayer.new()
	player_vitoria.stream = preload("res://Sons/vitoria.wav")
	player_vitoria.volume_db = 0
	add_child(player_vitoria)
	var _err = player_vitoria.connect("finished", player_vitoria, "play")
	player_vitoria.play()

func _construir_interface_tempos():
	# --- PAINEL DE TEMPOS (abaixo do SubTitulo/Descricao existentes) ---
	var painel_tempos = VBoxContainer.new()
	painel_tempos.name = "PainelTempos"
	painel_tempos.anchor_left = 0.5
	painel_tempos.anchor_right = 0.5
	painel_tempos.anchor_top = 0.48
	painel_tempos.margin_left = -200.0
	painel_tempos.margin_right = 200.0
	painel_tempos.margin_top = 0.0
	painel_tempos.set("custom_constants/separation", 6)
	add_child(painel_tempos)
	
	# Título dos tempos
	var titulo_tempos = Label.new()
	titulo_tempos.text = "SEUS TEMPOS"
	titulo_tempos.align = Label.ALIGN_CENTER
	titulo_tempos.add_color_override("font_color", Color(0.85, 0.75, 0.2, 1.0))
	titulo_tempos.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
	titulo_tempos.set("custom_constants/shadow_offset_x", 1)
	titulo_tempos.set("custom_constants/shadow_offset_y", 1)
	painel_tempos.add_child(titulo_tempos)
	
	# Separador
	var sep = HSeparator.new()
	sep.rect_min_size = Vector2(0, 4)
	painel_tempos.add_child(sep)
	
	# Tempos individuais
	var nomes_fases = ["Castelo", "Floresta", "Cemitério"]
	for i in range(3):
		var fase_num = i + 1
		var tempo = DadosJogo.tempos_fases[fase_num]
		var linha = HBoxContainer.new()
		linha.rect_min_size = Vector2(400, 24)
		
		var lbl_nome = Label.new()
		lbl_nome.text = "Fase " + str(fase_num) + " (" + nomes_fases[i] + "):"
		lbl_nome.add_color_override("font_color", Color(0.8, 0.8, 0.9, 1.0))
		lbl_nome.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl_nome.set("custom_constants/shadow_offset_x", 1)
		lbl_nome.set("custom_constants/shadow_offset_y", 1)
		lbl_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(lbl_nome)
		
		var lbl_tempo = Label.new()
		lbl_tempo.text = DadosJogo.formatar_tempo(tempo)
		lbl_tempo.add_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		lbl_tempo.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl_tempo.set("custom_constants/shadow_offset_x", 1)
		lbl_tempo.set("custom_constants/shadow_offset_y", 1)
		lbl_tempo.align = Label.ALIGN_RIGHT
		linha.add_child(lbl_tempo)
		
		painel_tempos.add_child(linha)
	
	# Separador antes do total
	var sep2 = HSeparator.new()
	sep2.rect_min_size = Vector2(0, 4)
	painel_tempos.add_child(sep2)
	
	# Tempo total
	var linha_total = HBoxContainer.new()
	linha_total.rect_min_size = Vector2(400, 28)
	
	var lbl_total_nome = Label.new()
	lbl_total_nome.text = "TEMPO TOTAL:"
	lbl_total_nome.add_color_override("font_color", Color(0.85, 0.75, 0.2, 1.0))
	lbl_total_nome.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
	lbl_total_nome.set("custom_constants/shadow_offset_x", 1)
	lbl_total_nome.set("custom_constants/shadow_offset_y", 1)
	lbl_total_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha_total.add_child(lbl_total_nome)
	
	var lbl_total_tempo = Label.new()
	lbl_total_tempo.text = DadosJogo.formatar_tempo(DadosJogo.obter_tempo_total())
	lbl_total_tempo.add_color_override("font_color", Color(0.85, 0.75, 0.2, 1.0))
	lbl_total_tempo.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
	lbl_total_tempo.set("custom_constants/shadow_offset_x", 1)
	lbl_total_tempo.set("custom_constants/shadow_offset_y", 1)
	lbl_total_tempo.align = Label.ALIGN_RIGHT
	linha_total.add_child(lbl_total_tempo)
	
	painel_tempos.add_child(linha_total)
	
	# --- CAMPO DE NOME E BOTÃO SALVAR ---
	var painel_nome = VBoxContainer.new()
	painel_nome.name = "PainelNome"
	painel_nome.anchor_left = 0.5
	painel_nome.anchor_right = 0.5
	painel_nome.anchor_top = 0.76
	painel_nome.margin_left = -160.0
	painel_nome.margin_right = 160.0
	painel_nome.margin_top = 0.0
	painel_nome.set("custom_constants/separation", 8)
	add_child(painel_nome)
	
	var lbl_instrucao = Label.new()
	lbl_instrucao.text = "Digite seu nome para o ranking:"
	lbl_instrucao.align = Label.ALIGN_CENTER
	lbl_instrucao.add_color_override("font_color", Color(0.7, 0.7, 0.8, 1.0))
	lbl_instrucao.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
	lbl_instrucao.set("custom_constants/shadow_offset_x", 1)
	lbl_instrucao.set("custom_constants/shadow_offset_y", 1)
	painel_nome.add_child(lbl_instrucao)
	
	campo_nome = LineEdit.new()
	campo_nome.name = "CampoNome"
	campo_nome.placeholder_text = "SEU NOME"
	campo_nome.max_length = 10
	campo_nome.align = LineEdit.ALIGN_CENTER
	campo_nome.rect_min_size = Vector2(320, 36)
	painel_nome.add_child(campo_nome)
	
	var linha_botoes = HBoxContainer.new()
	linha_botoes.alignment = BoxContainer.ALIGN_CENTER
	linha_botoes.set("custom_constants/separation", 16)
	painel_nome.add_child(linha_botoes)
	
	botao_salvar = Button.new()
	botao_salvar.name = "BotaoSalvarRanking"
	botao_salvar.text = "SALVAR NO RANKING"
	botao_salvar.rect_min_size = Vector2(180, 40)
	var _err = botao_salvar.connect("pressed", self, "_on_BotaoSalvarRanking_pressed")
	linha_botoes.add_child(botao_salvar)
	
	var botao_menu = Button.new()
	botao_menu.name = "BotaoMenuPrincipal2"
	botao_menu.text = "MENU PRINCIPAL"
	botao_menu.rect_min_size = Vector2(150, 40)
	var _err2 = botao_menu.connect("pressed", self, "_on_BotaoMenuPrincipal_pressed")
	linha_botoes.add_child(botao_menu)
	
	# Label de status (feedback ao salvar)
	label_status = Label.new()
	label_status.name = "LabelStatus"
	label_status.text = ""
	label_status.align = Label.ALIGN_CENTER
	label_status.add_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	label_status.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
	label_status.set("custom_constants/shadow_offset_x", 1)
	label_status.set("custom_constants/shadow_offset_y", 1)
	painel_nome.add_child(label_status)
	
	# Oculta o botão original de menu se existir (será substituído pelos novos)
	var botao_orig = get_node_or_null("BotaoMenuPrincipal")
	if botao_orig != null:
		botao_orig.visible = false

func _on_BotaoSalvarRanking_pressed():
	if ja_salvou:
		label_status.text = "Recorde já foi salvo!"
		return
	
	var nome = ""
	if campo_nome != null:
		nome = campo_nome.text.strip_edges()
	
	if nome.length() == 0:
		label_status.text = "Digite um nome primeiro!"
		label_status.add_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
		return
	
	DadosJogo.adicionar_recorde(nome)
	ja_salvou = true
	
	label_status.text = "Recorde salvo com sucesso!"
	label_status.add_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	
	if botao_salvar != null:
		botao_salvar.disabled = true
	if campo_nome != null:
		campo_nome.editable = false
	
	# Após 1.5s, vai automaticamente para a tela de ranking
	yield(get_tree().create_timer(1.5), "timeout")
	var _r = get_tree().change_scene("res://TelaRanking.tscn")

func _on_BotaoMenuPrincipal_pressed():
	# Volta para o menu principal
	var _voltar = get_tree().change_scene("res://MenuPrincipal.tscn")
