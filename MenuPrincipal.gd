extends Control

# ===========================================================================
# MenuPrincipal.gd — Menu principal com opções: Jogar, Editor, Sair
# ===========================================================================

func _ready():
	# Ajusta os textos e oculta o botão redundante
	var botao_iniciar = get_node_or_null("BotaoIniciar")
	if botao_iniciar:
		botao_iniciar.text = "JOGAR"
		
	var botao_orig = get_node_or_null("BotaoFaseOriginal")
	if botao_orig:
		botao_orig.visible = false

	var check_tut = get_node_or_null("CheckTutorial")
	if check_tut:
		check_tut.pressed = DadosJogo.tutorial_ativo

	print("MenuPrincipal: Inicializado com a capa estática do menu.")

func _on_BotaoIniciar_pressed():
	# Reseta os dados e carrega a Fase 1 original (com jogabilidade e arte nativa de alta qualidade)
	DadosJogo.resetar_para_nova_partida()
	var _mudar = get_tree().change_scene("res://Fase1.tscn")

func _on_BotaoEditor_pressed():
	# Abre o editor de fases integrado
	DadosJogo.modo_editor = true
	var _mudar = get_tree().change_scene("res://EditorFases.tscn")

func _on_BotaoFaseOriginal_pressed():
	# Redirecionado para o jogo normal
	_on_BotaoIniciar_pressed()

func _on_BotaoSair_pressed():
	get_tree().quit()

func _on_CheckTutorial_toggled(button_pressed):
	DadosJogo.tutorial_ativo = button_pressed
	print("MenuPrincipal: Estado do tutorial alterado para: ", button_pressed)
