extends Control

# ===========================================================================
# MenuFasesCustom.gd — Lista de fases customizadas criadas pelo jogador
# Lê de user://fases_custom/ e permite jogar qualquer uma delas
# ===========================================================================

var lista_fases = []

func _ready():
	_listar_fases()
	_construir_interface()

func _listar_fases():
	lista_fases.clear()
	var dir = Directory.new()
	if dir.open("user://fases_custom") != OK:
		print("[FasesCustom] Pasta user://fases_custom nao encontrada.")
		return
	
	dir.list_dir_begin(true, true)
	var nome_arq = dir.get_next()
	while nome_arq != "":
		if nome_arq.ends_with(".lvl"):
			lista_fases.append(nome_arq)
		nome_arq = dir.get_next()
	dir.list_dir_end()
	
	lista_fases.sort()
	print("[FasesCustom] %d fases encontradas." % lista_fases.size())

func _construir_interface():
	# Fundo escuro
	var fundo = ColorRect.new()
	fundo.anchor_right = 1.0
	fundo.anchor_bottom = 1.0
	fundo.color = Color(0.05, 0.05, 0.08)
	add_child(fundo)
	
	# Título
	var titulo = Label.new()
	titulo.text = "FASES CUSTOMIZADAS"
	titulo.align = Label.ALIGN_CENTER
	titulo.anchor_left = 0.5
	titulo.anchor_right = 0.5
	titulo.margin_left = -200
	titulo.margin_right = 200
	titulo.margin_top = 30
	titulo.margin_bottom = 70
	titulo.add_color_override("font_color", Color(0.95, 0.88, 0.55))
	add_child(titulo)
	
	# Scroll container para a lista
	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0.5
	scroll.anchor_right = 0.5
	scroll.margin_left = -250
	scroll.margin_right = 250
	scroll.margin_top = 80
	scroll.margin_bottom = -80
	scroll.anchor_bottom = 1.0
	add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.rect_min_size = Vector2(500, 0)
	vbox.set("custom_constants/separation", 8)
	scroll.add_child(vbox)
	
	if lista_fases.size() == 0:
		var msg = Label.new()
		msg.text = "Nenhuma fase customizada encontrada.\n\nCrie fases no Editor de Fases (Ctrl+S para salvar)."
		msg.align = Label.ALIGN_CENTER
		msg.add_color_override("font_color", Color(0.6, 0.6, 0.7))
		msg.autowrap = true
		msg.rect_min_size = Vector2(500, 100)
		vbox.add_child(msg)
	else:
		for nome_arq in lista_fases:
			var nome_display = nome_arq.replace(".lvl", "").replace("_", " ")
			
			var hbox = HBoxContainer.new()
			hbox.rect_min_size = Vector2(500, 40)
			hbox.set("custom_constants/separation", 10)
			
			# Botão de jogar
			var btn_jogar = Button.new()
			btn_jogar.text = "JOGAR: " + nome_display
			btn_jogar.rect_min_size = Vector2(350, 36)
			btn_jogar.connect("pressed", self, "_ao_jogar_fase", [nome_arq])
			hbox.add_child(btn_jogar)
			
			# Botão de editar
			var btn_editar = Button.new()
			btn_editar.text = "EDITAR"
			btn_editar.rect_min_size = Vector2(80, 36)
			btn_editar.connect("pressed", self, "_ao_editar_fase", [nome_arq])
			hbox.add_child(btn_editar)
			
			# Botão de excluir
			var btn_excluir = Button.new()
			btn_excluir.text = "X"
			btn_excluir.rect_min_size = Vector2(36, 36)
			btn_excluir.connect("pressed", self, "_ao_excluir_fase", [nome_arq])
			hbox.add_child(btn_excluir)
			
			vbox.add_child(hbox)
	
	# Botões inferiores
	var painel_inferior = HBoxContainer.new()
	painel_inferior.anchor_left = 0.5
	painel_inferior.anchor_right = 0.5
	painel_inferior.anchor_top = 1.0
	painel_inferior.anchor_bottom = 1.0
	painel_inferior.margin_left = -200
	painel_inferior.margin_right = 200
	painel_inferior.margin_top = -60
	painel_inferior.margin_bottom = -20
	painel_inferior.alignment = BoxContainer.ALIGN_CENTER
	painel_inferior.set("custom_constants/separation", 20)
	add_child(painel_inferior)
	
	var btn_editor = Button.new()
	btn_editor.text = "ABRIR EDITOR"
	btn_editor.rect_min_size = Vector2(160, 40)
	btn_editor.connect("pressed", self, "_ao_abrir_editor")
	painel_inferior.add_child(btn_editor)
	
	var btn_voltar = Button.new()
	btn_voltar.text = "VOLTAR"
	btn_voltar.rect_min_size = Vector2(120, 40)
	btn_voltar.connect("pressed", self, "_ao_voltar")
	painel_inferior.add_child(btn_voltar)

func _ao_jogar_fase(nome_arq: String):
	var caminho = "user://fases_custom/" + nome_arq
	DadosJogo.modo_editor = true
	DadosJogo.caminho_fase_custom = caminho
	DadosJogo.energia_vital = 100.0
	print("[FasesCustom] Jogando fase: " + caminho)
	var _r = get_tree().change_scene("res://FaseCarregada.tscn")

func _ao_editar_fase(nome_arq: String):
	# Salva o caminho para o editor carregar automaticamente
	DadosJogo.modo_editor = true
	DadosJogo.caminho_fase_custom = "user://fases_custom/" + nome_arq
	print("[FasesCustom] Editando fase: " + nome_arq)
	var _r = get_tree().change_scene("res://EditorFases.tscn")

func _ao_excluir_fase(nome_arq: String):
	var dir = Directory.new()
	var caminho = "user://fases_custom/" + nome_arq
	if dir.file_exists(caminho):
		dir.remove(caminho)
		print("[FasesCustom] Fase excluida: " + nome_arq)
	# Recarrega a cena para atualizar a lista
	var _r = get_tree().change_scene("res://MenuFasesCustom.tscn")

func _ao_abrir_editor():
	DadosJogo.modo_editor = true
	DadosJogo.caminho_fase_custom = ""
	var _r = get_tree().change_scene("res://EditorFases.tscn")

func _ao_voltar():
	var _r = get_tree().change_scene("res://MenuPrincipal.tscn")
