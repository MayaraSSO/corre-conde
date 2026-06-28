extends KinematicBody

var estaca_molde = preload("res://Estaca.tscn")
var anel_cena = preload("res://PedacoAnel.tscn")

var saude = 100.0
var hipnotizado = false
var desintegrando = false
var temporizador_espera = 6.0
var temporizador_morte = 1.8
var velocidade_perseguicao = 15.2 # Metros por segundo (3.8 * 4.0 escala)
var gravidade = 35.0
var velocidade_y = 0.0

var conde_ref = null
var material : SpatialMaterial
var acordado = false

onready var mesh_inst = $MeshInstance

func _ready():
	# Configura material único para modular a cor do lobo
	material = mesh_inst.get_surface_material(0)
	if material == null and mesh_inst.mesh != null:
		material = mesh_inst.mesh.surface_get_material(0)
	if material != null:
		material = material.duplicate()
		mesh_inst.set_surface_material(0, material)
		# Inicialmente marrom escuro
		material.albedo_color = Color(0.4, 0.2, 0.1)

func _physics_process(delta):
	# Gravidade simples para mantê-lo no chão
	if not is_on_floor():
		velocidade_y -= gravidade * delta
	else:
		velocidade_y = 0.0
		
	var movimento = Vector3.ZERO
	movimento.y = velocidade_y
	
	# Busca o Conde
	var conde = get_parent().get_node_or_null("Conde")
	if conde == null:
		var _mov = move_and_slide(movimento, Vector3.UP)
		return
		
	# Ativa o Lobo quando o Conde se aproxima da arena (X >= 470.0)
	if not acordado and conde.translation.x >= 470.0:
		acordado = true
		print("[Lobisomem] Conde entrou na arena! Fera acordando...")
		
	if acordado:
		if not desintegrando:
			if not hipnotizado:
				# 1. ESPREITA (6.0 segundos)
				if temporizador_espera > 0.0:
					temporizador_espera -= delta
					# Exibe contagem regressiva no HUD do Conde
					var texto_hud = conde.get_node_or_null("HUD/TextoAnel")
					if texto_hud != null:
						texto_hud.text = "ESPREITANDO... (%.1fs)" % temporizador_espera
				else:
					# 2. CAÇA e persegue o Conde
					var texto_hud = conde.get_node_or_null("HUD/TextoAnel")
					if texto_hud != null:
						texto_hud.text = "LOBO HP: %d%% | MORDA COM [Z]!" % int(saude)
						
					var dir = 0
					if translation.x > conde.translation.x:
						dir = -1
					else:
						dir = 1
					movimento.x = dir * velocidade_perseguicao
			else:
				# 3. HIPNOTIZADO
				var texto_hud = conde.get_node_or_null("HUD/TextoAnel")
				if texto_hud != null:
					texto_hud.text = "HIPNOTIZADO! MORDA!"
				# Muda material para roxo brilhante
				if material != null:
					material.albedo_color = Color(0.8, 0.1, 0.8)
		else:
			# 4. DESINTEGRANDO (1.8s)
			temporizador_morte -= delta
			var texto_hud = conde.get_node_or_null("HUD/TextoAnel")
			if texto_hud != null:
				texto_hud.text = "SUCUMBINDO..."
				
			if material != null:
				var flash = sin(OS.get_ticks_msec() * 0.025) * 0.4 + 0.6
				material.albedo_color = Color(0.6, 0.2, 0.6, 0.3 + 0.7 * flash) # Roxo moribundo piscante
				
			if temporizador_morte <= 0.0:
				desintegrando = false
				print("[Lobisomem] Fera derrotada de vez! Spawning anel de vitória.")
				var novo_anel = anel_cena.instance()
				novo_anel.translation = self.translation
				novo_anel.translation.y = 1.0
				get_parent().add_child(novo_anel)
				queue_free()
				
	# Trava o movimento em Z
	movimento.z = 0.0
	var _mov = move_and_slide(movimento, Vector3.UP)

func _on_AreaDano_body_entered(body):
	if not acordado or desintegrando:
		return
		
	if body.name == "Conde":
		if not hipnotizado:
			# Se o Conde estiver espreitando ou ativo de Parry (Z)
			if body.temporizador_parry > 0.0:
				# Parry Funcional! Lobo toma dano
				saude -= 25.0
				body.temporizador_parry = 0.0 # Consome o parry
				
				# Lobo é repelido para trás (à direita)
				translation.x += 35.0 # Repulsão física de 140px em C (140/4)
				print("[Lobisomem] Parry recebido! HP restante: ", saude)
				
				if saude <= 0.0:
					saude = 0.0
					hipnotizado = true
					print("[Lobisomem] Hipnotizado e atordoado!")
			else:
				# Conde falhou no parry e é atacado!
				body.energia_vital -= 15.0
				body.tempo_exibir_dano = 0.35 # Ativa flash de dano
				var barra = body.get_node_or_null("HUD/BarraVida")
				if barra != null:
					barra.value = body.energia_vital
					
				# Repele o Conde para trás (esquerda)
				body.translation.x -= 12.5 # Repulsão de 50px em C
				body.velocidade.y = 16.0 # Lança Conde para o alto
				print("[Lobisomem] Conde atacado! HP Conde: ", body.energia_vital)
				
				# Game Over se a vida zerar
				if body.energia_vital <= 0.0:
					body.energia_vital = 0.0
					body.morrer("lobisomem")
		else:
			# Conde morde o lobo hipnotizado! Inicia a morte cinematográfica
			print("[Lobisomem] Conde mordeu a fera! Desintegrando...")
			desintegrando = true
			
			# Cura o Conde completamente
			body.energia_vital = 100.0
			var barra = body.get_node_or_null("HUD/BarraVida")
			if barra != null:
				barra.value = body.energia_vital
				
			# Repele ligeiramente o Conde para trás para dar enquadramento visual
			body.translation.x -= 10.0
			
			# Trava a velocidade da ZonaLuz
			var zona = get_parent().get_node_or_null("ZonaLuz")
			if zona != null:
				zona.set_process(false)
