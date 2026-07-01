extends Control

var texto_etapas = [
	"Após derrotar o Paladino Supremo nas catacumbas do Cemitério...",
	"O Conde reuniu todos os fragmentos e restaurou o Anel Ancestral!",
	"Com a imunidade solar definitiva e seus plenos poderes restaurados...",
	"Ele retorna triunfante para reinar para sempre em seu Castelo da Noite!"
]

var etapa_atual = 0
var tempo_etapa = 0.0

onready var overlay = $Overlay
onready var conde = $CondeSprite
onready var texto_label = $TextContainer/LabelTexto
onready var audio_music = $AudioMusic
onready var audio_steps = $AudioSteps

var conde_andando = false
var conde_pos_inicial = Vector2(-150, 420)
var conde_pos_final = Vector2(400, 420) # anda até perto da porta do castelo
var velocidade_conde = 120.0 # pixels por segundo
var tempo_animacao_sprite = 0.0
var frame_rate_sprite = 10.0

# Sons
var som_passos = preload("res://Sons/dois passos andando.wav")
var musica_misterio = preload("res://Sons/Trilha misteriosa todas as fases.mp3")
var som_vitoria = preload("res://Sons/vitoria.wav")

var tempo_som_passos = 0.0

# Estado geral da cutscene
# "fade_in" -> "texto0" -> "texto1" -> "conde_entra" -> "texto2" -> "fade_out" -> "mudar_fase"
var estado = "fade_in"
var tempo_estado = 0.0

func _ready():
	# Configura áudio da música misteriosa inicial
	# Configura áudio da música de vitória em looping logo no início
	audio_music.stream = som_vitoria
	audio_music.volume_db = -4 # Volume adequado
	if not audio_music.is_connected("finished", audio_music, "play"):
		var _err = audio_music.connect("finished", audio_music, "play")
	audio_music.play()
	
	# Configura áudio de passos
	audio_steps.stream = som_passos
	audio_steps.volume_db = -5
	
	# Configura estado inicial dos elementos visuais
	overlay.color = Color(0, 0, 0, 1)
	overlay.visible = true
	
	# Conde começa correndo da esquerda
	conde.texture = sheet_correndo
	conde.hframes = 8
	conde.frame = 0
	conde.position = conde_pos_inicial
	conde.modulate.a = 1.0
	
	# Texto invisível
	texto_label.bbcode_text = ""
	texto_label.modulate.a = 0.0
	
	# Aumenta a escala do texto para que as letras fiquem maiores
	yield(get_tree(), "idle_frame")
	var container = get_node_or_null("TextContainer")
	if container != null:
		container.rect_pivot_offset = container.rect_size / 2
		container.rect_scale = Vector2(1.35, 1.35)
	
	print("[Cutscene] Iniciada.")

func _process(delta):
	tempo_estado += delta
	
	match estado:
		"fade_in":
			# Fade in inicial da cena
			var alpha = 1.0 - (tempo_estado / 2.0) # 2 segundos
			overlay.color = Color(0, 0, 0, clamp(alpha, 0.0, 1.0))
			if tempo_estado >= 2.0:
				overlay.visible = false
				ir_para_estado("texto0")
				
		"texto0":
			# Mostra o primeiro texto narrando a vitória do conde
			animar_texto(texto_etapas[0], delta)
			if tempo_estado >= 5.0: # Exibe por 5 segundos
				ir_para_estado("texto1")
				
		"texto1":
			# Mostra o segundo texto sobre os fragmentos do anel
			animar_texto(texto_etapas[1], delta)
			if tempo_estado >= 5.0:
				ir_para_estado("conde_entra")
				
		"conde_entra":
			# O Conde caminha até a porta
			conde_andando = true
			animar_conde(delta)
			
			# Exibe o terceiro texto enquanto ele caminha
			animar_texto(texto_etapas[2], delta)
			
			if conde.position.x >= conde_pos_final.x:
				# Ele para em frente ao castelo
				conde_andando = false
				conde.texture = sheet_parado
				conde.hframes = 5
				conde.frame = 0
				audio_steps.stop()
				ir_para_estado("texto2")
				
		"texto2":
			# Conde fica no ciclo de idle (animando parado em frente ao castelo)
			animar_conde_parado(delta)
			
			# Exibe o quarto texto sobre o retorno triunfal
			animar_texto(texto_etapas[3], delta)
			if tempo_estado >= 6.0:
				overlay.visible = true
				ir_para_estado("fade_out")
				
		"fade_out":
			# Conde continua respirando parado
			animar_conde_parado(delta)
			
			# Fade out para o preto
			var alpha = tempo_estado / 2.0 # 2 segundos
			overlay.color = Color(0, 0, 0, clamp(alpha, 0.0, 1.0))
			
			# Diminui suavemente o som de vitória
			audio_music.volume_db = -4 - (alpha * 40)
			
			if tempo_estado >= 2.0:
				ir_para_estado("mudar_fase")
				
		"mudar_fase":
			print("[Cutscene] Campanha concluída! Carregando Tela de Vitória...")
			var _r = get_tree().change_scene("res://TelaVitoria.tscn")

func ir_para_estado(novo_estado):
	estado = novo_estado
	tempo_estado = 0.0
	print("[Cutscene] Estado: ", novo_estado)
	
	if "texto" in novo_estado:
		texto_label.modulate.a = 0.0
	


func animar_texto(texto: String, delta: float):
	# Estilização do texto narrativo em BBCode com cor amarela e centralizado
	texto_label.bbcode_text = "[center][color=yellow]" + texto + "[/color][/center]"
	
	# Transição suave (fade-in e fade-out) de opacidade do texto
	if tempo_estado < 1.0:
		texto_label.modulate.a = tempo_estado # fade-in em 1s
	elif tempo_estado >= 4.0 and estado != "conde_entra": # fade-out de 1s antes de trocar (exceto se estiver andando que dura mais)
		texto_label.modulate.a = 1.0 - (tempo_estado - 4.0)
	else:
		texto_label.modulate.a = 1.0

func animar_conde(delta: float):
	if conde_andando:
		# Mover posição
		conde.position.x += velocidade_conde * delta
		
		# Animar sprites de corrida
		tempo_animacao_sprite += delta * frame_rate_sprite
		conde.frame = int(tempo_animacao_sprite) % 8
		
		# Tocar passos periodicamente
		tempo_som_passos += delta
		if tempo_som_passos >= 0.45:
			tempo_som_passos = 0.0
			audio_steps.play()

func animar_conde_parado(delta: float):
	# Animar sprites de respiração parado
	tempo_animacao_sprite += delta * 5.0 # 5 fps para o idle
	conde.frame = int(tempo_animacao_sprite) % 5

# As texturas são carregadas sob demanda ou pré-carregadas
var sheet_correndo = preload("res://Imagens/Conde_Correndo_Sheet.png")
var sheet_parado = preload("res://Imagens/Conde_Parado_Sheet.png")
