extends CanvasLayer

func _ready():
	# Começa escondido, já que o jogo inicia despausado
	$ColorRect.visible = false
	$BotaoContinuar.visible = false
	$BotaoMusica.visible = false
	$BotaoMenu.visible = false

func _input(event):
	# Se apertar o botão ESC (ui_cancel) do teclado
	if event.is_action_pressed("ui_cancel"):
		# Inverte o estado atual do jogo (se tá pausado, despausa. Se tá rodando, pausa)
		var novo_estado_pause = not get_tree().paused
		get_tree().paused = novo_estado_pause
		
		# Mostra ou esconde os botões na tela
		$ColorRect.visible = novo_estado_pause
		$BotaoContinuar.visible = novo_estado_pause
		$BotaoMusica.visible = novo_estado_pause
		$BotaoMenu.visible = novo_estado_pause

func _on_BotaoContinuar_pressed():
	# Tira o pause e esconde a tela
	get_tree().paused = false
	$ColorRect.visible = false
	$BotaoContinuar.visible = false
	$BotaoMusica.visible = false
	$BotaoMenu.visible = false

func _on_BotaoMusica_pressed():
	# Lógica para mutar/desmutar todo o áudio do jogo
	var bus_idx = AudioServer.get_bus_index("Master")
	var esta_mutado = AudioServer.is_bus_mute(bus_idx)
	
	AudioServer.set_bus_mute(bus_idx, not esta_mutado)
	
	# Muda o texto do botão para o jogador saber
	if not esta_mutado:
		$BotaoMusica.text = "MÚSICA: DESLIGADA"
	else:
		$BotaoMusica.text = "MÚSICA: LIGADA"

func _on_BotaoMenu_pressed():
	# IMPORTANTE: Despausa o motor do jogo antes de mudar de cena
	get_tree().paused = false
	var _voltar = get_tree().change_scene("res://MenuPrincipal.tscn")
