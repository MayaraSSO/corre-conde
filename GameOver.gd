extends Control

func _ready():
	var motivo_morte = "sol"
	var arquivo = File.new()
	if arquivo.file_exists("user://motivo_morte.txt"):
		var _erro = arquivo.open("user://motivo_morte.txt", File.READ)
		motivo_morte = arquivo.get_as_text().strip_edges()
		arquivo.close()
		
	if motivo_morte == "queda":
		$TituloGameOver.text = "O CONDE DESPENCOU!"
		$SubTitulo.text = "A queda no abismo foi fatal."
	elif motivo_morte == "sol":
		$TituloGameOver.text = "O CONDE VIROU CINZAS!"
		$SubTitulo.text = "A luz do sol foi implacável..."
	elif motivo_morte == "paladino":
		$TituloGameOver.text = "O PALADINO VENCEU!"
		$SubTitulo.text = "Você foi derrotado pelo campeão da luz."
	elif motivo_morte == "lobo" or motivo_morte == "lobisomem":
		$TituloGameOver.text = "O CONDE FOI DEVORADO!"
		$SubTitulo.text = "Os lobos da floresta venceram esta batalha."
	elif motivo_morte == "crucifixo":
		$TituloGameOver.text = "O CONDE FOI EXPULSO!"
		$SubTitulo.text = "O poder sagrado do crucifixo destruiu suas forças."
	elif motivo_morte == "caixao":
		$TituloGameOver.text = "O CONDE FOI SOTERRADO!"
		$SubTitulo.text = "O caixão quebradiço das catacumbas cedeu sob seus pés."
	else:
		$TituloGameOver.text = "O CONDE FOI DERROTADO!"
		$SubTitulo.text = "Você sucumbiu aos perigos do cenário."

func _on_BotaoTentarNovamente_pressed():
	# Reinicia na fase atual em que o jogador estava
	if DadosJogo.modo_editor:
		var _recarregar = get_tree().change_scene("res://FaseCarregada.tscn")
	else:
		var caminho_cena = "res://Fase" + str(DadosJogo.fase_atual) + ".tscn"
		var _recarregar = get_tree().change_scene(caminho_cena)

func _on_BotaoMenuPrincipal_pressed():
	if DadosJogo.modo_editor:
		if DadosJogo.caminho_fase_custom == "user://editor_teste.lvl":
			var _voltar = get_tree().change_scene("res://EditorFases.tscn")
		else:
			var _voltar = get_tree().change_scene("res://MenuFasesCustom.tscn")
	else:
		var _voltar = get_tree().change_scene("res://MenuPrincipal.tscn")
