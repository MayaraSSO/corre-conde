extends Area

export var velocidade_perseguicao = 5.0
var perseguindo = false
var tempo_espera = 2.0

# --- SOM DE DANO SOLAR ---
var som_luz_sol_res = preload("res://Sons/Luz do Sol (Dano do Sol).mp3")
var player_luz_sol : AudioStreamPlayer
var _audio_pronto = false

func _ready():
	player_luz_sol = AudioStreamPlayer.new()
	player_luz_sol.stream = som_luz_sol_res
	add_child(player_luz_sol)
	_audio_pronto = true

func _process(delta):
	# 1. Movimento da Parede de Luz
	if perseguindo:
		if tempo_espera > 0:
			tempo_espera -= delta
		else:
			var vel_atual = velocidade_perseguicao
			var conde = get_parent().get_node_or_null("Conde")
			# Se o Conde estiver abrigado na sombra (imune ao sol)
			if conde != null and conde.imune_ao_sol and conde.pedacos_coletados < conde.total_pedacos:
				vel_atual = velocidade_perseguicao * 0.25 # Desacelera para 25% da velocidade
			translation.x += vel_atual * delta
			
	# 2. Sistema de Dano Contínuo da Luz Solar
	# Todo ponto à esquerda do limite da onda de luz está ensolarado
	if perseguindo:
		var conde = get_parent().get_node_or_null("Conde")
		if conde != null:
			var limite_sol = translation.x # A frente física e visual está alinhada com a posição X
			if conde.translation.x < limite_sol and not conde.imune_ao_sol:
				# O Conde está na luz solar!
				# Tiramos 25.0 de vida por segundo e ativamos a flag de animação solar
				conde.energia_vital -= 25.0 * delta
				conde.sofrendo_dano_sol = true
				
				# Toca o som de dano solar (apenas se não estiver já tocando)
				if _audio_pronto and player_luz_sol != null and not player_luz_sol.playing:
					player_luz_sol.play()
				
				var hud_barra = conde.get_node_or_null("HUD/BarraVida")
				if hud_barra != null:
					hud_barra.value = conde.energia_vital
					
				# Se a energia acabou, chama o morrer do conde
				if conde.energia_vital <= 0:
					conde.energia_vital = 0
					conde.morrer("sol")
			else:
				# Conde saiu da luz ou está imune — para o som
				if _audio_pronto and player_luz_sol != null and player_luz_sol.playing:
					player_luz_sol.stop()

