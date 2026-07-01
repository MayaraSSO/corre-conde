extends Control

# ===========================================================================
# TelaRanking.gd — Tela de ranking com os 10 melhores tempos
# Exibe tempo de cada fase + tempo total para cada registro
# ===========================================================================

var container_ranking : VBoxContainer = null

func _ready():
	# Recarrega os dados do ranking (pode ter sido salvo recentemente)
	DadosJogo.carregar_ranking()
	_construir_interface()

func _construir_interface():
	# --- FUNDO ESCURO GÓTICO ---
	var fundo = ColorRect.new()
	fundo.name = "Fundo"
	fundo.anchor_right = 1.0
	fundo.anchor_bottom = 1.0
	fundo.color = Color(0.02, 0.02, 0.08, 1.0)
	add_child(fundo)
	
	# --- TÍTULO ---
	var titulo = Label.new()
	titulo.name = "TituloRanking"
	titulo.anchor_left = 0.5
	titulo.anchor_right = 0.5
	titulo.margin_left = -300.0
	titulo.margin_right = 300.0
	titulo.margin_top = 20.0
	titulo.margin_bottom = 65.0
	titulo.text = "RANKING DOS MELHORES TEMPOS"
	titulo.align = Label.ALIGN_CENTER
	titulo.valign = Label.VALIGN_CENTER
	
	# Efeito de sombra para visual premium
	titulo.add_color_override("font_color", Color(0.85, 0.75, 0.2, 1.0))
	titulo.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
	titulo.set("custom_constants/shadow_offset_x", 1)
	titulo.set("custom_constants/shadow_offset_y", 1)
	add_child(titulo)
	
	# --- CABEÇALHO DA TABELA ---
	var cabecalho = HBoxContainer.new()
	cabecalho.name = "Cabecalho"
	cabecalho.anchor_left = 0.5
	cabecalho.anchor_right = 0.5
	cabecalho.margin_left = -420.0
	cabecalho.margin_right = 420.0
	cabecalho.margin_top = 75.0
	cabecalho.margin_bottom = 100.0
	cabecalho.set("custom_constants/separation", 8)
	add_child(cabecalho)
	
	var colunas_cab = ["#", "NOME", "FASE 1", "FASE 2", "FASE 3", "TOTAL", "DATA"]
	var larguras_cab = [30, 120, 85, 85, 85, 90, 100]
	
	for i in range(colunas_cab.size()):
		var lbl = Label.new()
		lbl.text = colunas_cab[i]
		lbl.rect_min_size = Vector2(larguras_cab[i], 24)
		lbl.add_color_override("font_color", Color(0.6, 0.55, 0.3, 1.0))
		lbl.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl.set("custom_constants/shadow_offset_x", 1)
		lbl.set("custom_constants/shadow_offset_y", 1)
		if i == 0:
			lbl.align = Label.ALIGN_CENTER
		elif i == 1:
			lbl.align = Label.ALIGN_LEFT
		else:
			lbl.align = Label.ALIGN_RIGHT
		cabecalho.add_child(lbl)
	
	# Separador
	var sep = HSeparator.new()
	sep.anchor_left = 0.5
	sep.anchor_right = 0.5
	sep.margin_left = -420.0
	sep.margin_right = 420.0
	sep.margin_top = 100.0
	sep.margin_bottom = 104.0
	add_child(sep)
	
	# --- CONTAINER DAS LINHAS DO RANKING ---
	container_ranking = VBoxContainer.new()
	container_ranking.name = "ContainerRanking"
	container_ranking.anchor_left = 0.5
	container_ranking.anchor_right = 0.5
	container_ranking.margin_left = -420.0
	container_ranking.margin_right = 420.0
	container_ranking.margin_top = 108.0
	container_ranking.margin_bottom = 500.0
	container_ranking.set("custom_constants/separation", 4)
	add_child(container_ranking)
	
	_popular_ranking()
	
	# --- BOTÃO VOLTAR ---
	var botao_voltar = Button.new()
	botao_voltar.name = "BotaoVoltar"
	botao_voltar.text = "VOLTAR AO MENU"
	botao_voltar.anchor_left = 0.5
	botao_voltar.anchor_right = 0.5
	botao_voltar.anchor_top = 1.0
	botao_voltar.anchor_bottom = 1.0
	botao_voltar.margin_left = -100.0
	botao_voltar.margin_right = 100.0
	botao_voltar.margin_top = -70.0
	botao_voltar.margin_bottom = -30.0
	var _err = botao_voltar.connect("pressed", self, "_on_BotaoVoltar_pressed")
	add_child(botao_voltar)

func _popular_ranking():
	# Limpa linhas anteriores
	for child in container_ranking.get_children():
		child.queue_free()
	
	if DadosJogo.ranking_dados.size() == 0:
		var lbl_vazio = Label.new()
		lbl_vazio.text = "Nenhum recorde registrado ainda. Complete o jogo para aparecer aqui!"
		lbl_vazio.align = Label.ALIGN_CENTER
		lbl_vazio.add_color_override("font_color", Color(0.5, 0.5, 0.6, 1.0))
		lbl_vazio.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl_vazio.set("custom_constants/shadow_offset_x", 1)
		lbl_vazio.set("custom_constants/shadow_offset_y", 1)
		container_ranking.add_child(lbl_vazio)
		return
	
	var larguras = [30, 120, 85, 85, 85, 90, 100]
	
	for idx in range(DadosJogo.ranking_dados.size()):
		var registro = DadosJogo.ranking_dados[idx]
		var posicao = idx + 1
		var eh_primeiro = (posicao == 1)
		
		# Contêiner pai da linha que segura o fundo e o conteúdo
		var painel_linha = Control.new()
		painel_linha.name = "PainelLinha_" + str(posicao)
		painel_linha.rect_min_size = Vector2(840, 28)
		container_ranking.add_child(painel_linha)
		
		# Fundo alternado
		var bg = ColorRect.new()
		bg.name = "FundoAlternado"
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		bg.margin_left = 0
		bg.margin_top = 0
		bg.margin_right = 0
		bg.margin_bottom = 0
		if idx % 2 == 0:
			bg.color = Color(0.06, 0.06, 0.12, 0.5)
		else:
			bg.color = Color(0.04, 0.04, 0.08, 0.3)
		painel_linha.add_child(bg)
		
		# HBoxContainer real dos dados
		var linha = HBoxContainer.new()
		linha.name = "Linha"
		linha.anchor_right = 1.0
		linha.anchor_bottom = 1.0
		linha.margin_left = 0
		linha.margin_top = 0
		linha.margin_right = 0
		linha.margin_bottom = 0
		linha.set("custom_constants/separation", 8)
		painel_linha.add_child(linha)
		
		var cor_texto = Color(0.85, 0.85, 0.9, 1.0)
		if eh_primeiro:
			cor_texto = Color(1.0, 0.85, 0.2, 1.0)  # Dourado
		elif posicao <= 3:
			cor_texto = Color(0.8, 0.7, 0.5, 1.0)  # Dourado suave
		
		# Posição
		var lbl_pos = Label.new()
		if eh_primeiro:
			lbl_pos.text = "1"
		else:
			lbl_pos.text = str(posicao)
		lbl_pos.rect_min_size = Vector2(larguras[0], 28)
		lbl_pos.add_color_override("font_color", cor_texto)
		lbl_pos.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl_pos.set("custom_constants/shadow_offset_x", 1)
		lbl_pos.set("custom_constants/shadow_offset_y", 1)
		lbl_pos.align = Label.ALIGN_CENTER
		lbl_pos.valign = Label.VALIGN_CENTER
		linha.add_child(lbl_pos)
		
		# Nome
		var lbl_nome = Label.new()
		lbl_nome.text = str(registro.get("nome", "???"))
		lbl_nome.rect_min_size = Vector2(larguras[1], 28)
		lbl_nome.add_color_override("font_color", cor_texto)
		lbl_nome.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl_nome.set("custom_constants/shadow_offset_x", 1)
		lbl_nome.set("custom_constants/shadow_offset_y", 1)
		lbl_nome.align = Label.ALIGN_LEFT
		lbl_nome.valign = Label.VALIGN_CENTER
		lbl_nome.clip_text = true
		linha.add_child(lbl_nome)
		
		# Fase 1
		var lbl_f1 = Label.new()
		lbl_f1.text = DadosJogo.formatar_tempo(float(registro.get("tempo_fase1", 0.0)))
		lbl_f1.rect_min_size = Vector2(larguras[2], 28)
		lbl_f1.add_color_override("font_color", cor_texto)
		lbl_f1.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl_f1.set("custom_constants/shadow_offset_x", 1)
		lbl_f1.set("custom_constants/shadow_offset_y", 1)
		lbl_f1.align = Label.ALIGN_RIGHT
		lbl_f1.valign = Label.VALIGN_CENTER
		linha.add_child(lbl_f1)
		
		# Fase 2
		var lbl_f2 = Label.new()
		lbl_f2.text = DadosJogo.formatar_tempo(float(registro.get("tempo_fase2", 0.0)))
		lbl_f2.rect_min_size = Vector2(larguras[3], 28)
		lbl_f2.add_color_override("font_color", cor_texto)
		lbl_f2.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl_f2.set("custom_constants/shadow_offset_x", 1)
		lbl_f2.set("custom_constants/shadow_offset_y", 1)
		lbl_f2.align = Label.ALIGN_RIGHT
		lbl_f2.valign = Label.VALIGN_CENTER
		linha.add_child(lbl_f2)
		
		# Fase 3
		var lbl_f3 = Label.new()
		lbl_f3.text = DadosJogo.formatar_tempo(float(registro.get("tempo_fase3", 0.0)))
		lbl_f3.rect_min_size = Vector2(larguras[4], 28)
		lbl_f3.add_color_override("font_color", cor_texto)
		lbl_f3.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl_f3.set("custom_constants/shadow_offset_x", 1)
		lbl_f3.set("custom_constants/shadow_offset_y", 1)
		lbl_f3.align = Label.ALIGN_RIGHT
		lbl_f3.valign = Label.VALIGN_CENTER
		linha.add_child(lbl_f3)
		
		# Tempo Total
		var lbl_total = Label.new()
		lbl_total.text = DadosJogo.formatar_tempo(float(registro.get("tempo_total", 0.0)))
		lbl_total.rect_min_size = Vector2(larguras[5], 28)
		lbl_total.add_color_override("font_color", cor_texto)
		lbl_total.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl_total.set("custom_constants/shadow_offset_x", 1)
		lbl_total.set("custom_constants/shadow_offset_y", 1)
		lbl_total.align = Label.ALIGN_RIGHT
		lbl_total.valign = Label.VALIGN_CENTER
		linha.add_child(lbl_total)
		
		# Data
		var lbl_data = Label.new()
		lbl_data.text = str(registro.get("data", ""))
		lbl_data.rect_min_size = Vector2(larguras[6], 28)
		lbl_data.add_color_override("font_color", Color(0.5, 0.5, 0.6, 1.0))
		lbl_data.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 1.0))
		lbl_data.set("custom_constants/shadow_offset_x", 1)
		lbl_data.set("custom_constants/shadow_offset_y", 1)
		lbl_data.align = Label.ALIGN_RIGHT
		lbl_data.valign = Label.VALIGN_CENTER
		linha.add_child(lbl_data)

func _on_BotaoVoltar_pressed():
	var _r = get_tree().change_scene("res://MenuPrincipal.tscn")
