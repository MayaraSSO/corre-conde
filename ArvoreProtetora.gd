extends Spatial

# Parâmetros calibrados para o motor físico do Godot
var altura_atual = 0.5
var altura_maxima = 4.5
var velocidade_crescimento = 2.5 # Metros por segundo

var ativa = false
var conde_ref = null
var vida_recuperada = false

onready var tronco = $Tronco
onready var copa = $Copa
onready var sombra_visual = $SombraVisual
onready var colisor_sombra = $AreaSombra/CollisionShape

# --- SOM DA ÁRVORE ---
var som_arvore_res = preload("res://Sons/arvore crescendo.mp3")
var player_arvore : AudioStreamPlayer

func _ready():
	# Inicializa pequena e invisível (será ativada por inicializar())
	visible = false
	if colisor_sombra != null and colisor_sombra.shape != null:
		colisor_sombra.shape = colisor_sombra.shape.duplicate()
	
	# Inicializa com escala bem reduzida com base na altura inicial (0.5) e multiplicador de tamanho (2.2)
	var fator_inicial = 0.5 / altura_maxima
	var tamanho_final = 2.2
	var escala_inicial = fator_inicial * tamanho_final
	
	tronco.scale = Vector3(escala_inicial, escala_inicial, escala_inicial)
	copa.scale = Vector3(escala_inicial, escala_inicial, escala_inicial)
	copa.translation.y = 2.0 * escala_inicial
	
	sombra_visual.scale = Vector3(0.01, 1.0, 1.0)
	colisor_sombra.disabled = true
	# Inicializa player de áudio
	player_arvore = AudioStreamPlayer.new()
	if som_arvore_res != null:
		som_arvore_res.loop = false # Garante que o MP3 toque apenas uma vez
	player_arvore.stream = som_arvore_res
	add_child(player_arvore)

func inicializar(pos_x, pos_y = 0.0):
	var x_alinhado = _obter_x_chao_mais_proximo(pos_x)
	translation.x = x_alinhado
	translation.y = _obter_altura_chao_em(x_alinhado, pos_y)
	translation.z = 0.0
	altura_atual = 0.5
	ativa = true
	visible = true
	copa.visible = true
	colisor_sombra.disabled = false
	print("[ArvoreProtetora] Plantada no chão em X: ", x_alinhado, " Y: ", translation.y)
	
	# Toca o som de árvore crescendo
	if player_arvore != null:
		player_arvore.play()

func _process(delta):
	if not ativa:
		return
		
	if altura_atual < altura_maxima:
		altura_atual += velocidade_crescimento * delta
		if altura_atual > altura_maxima:
			altura_atual = altura_maxima
			
	# Fator de crescimento linear de 0.11 a 1.0
	var fator = altura_atual / altura_maxima
	
	# Ajusta a escala final multiplicando pelo tamanho desejado da árvore (2.2x maior)
	var tamanho_final = 2.2
	var escala_final = fator * tamanho_final
	
	# Atualiza a escala do Tronco e da Copa proporcionalmente
	# Isso impede a distorção das texturas e mantém a geometria da árvore correta
	tronco.scale = Vector3(escala_final, escala_final, escala_final)
	copa.scale = Vector3(escala_final, escala_final, escala_final)
	
	# A copa acompanha o topo do tronco (que tem altura 2.0 na escala 1.0)
	copa.translation.y = 2.0 * escala_final
	
	# Projeção de Sombra proporcional ao novo tamanho da árvore
	var comp_sombra_desejado = altura_atual * 2.2 * tamanho_final
	
	# Limita o comprimento da sombra à borda do chão disponível
	var borda_direita = _obter_borda_chao_direita(translation.x)
	var distancia_ate_borda = borda_direita - translation.x
	if distancia_ate_borda < 0.5:
		distancia_ate_borda = 0.5
	var comp_sombra = min(comp_sombra_desejado, distancia_ate_borda)
	
	# SombraVisual (QuadMesh de tamanho 1.0x1.0 deitado)
	# Escala horizontal X estica o comprimento da sombra
	sombra_visual.scale.x = comp_sombra
	# Posiciona o centro da sombra para a direita da árvore
	sombra_visual.translation.x = comp_sombra / 2.0
	sombra_visual.translation.y = 0.02 # Altura mínima para evitar clipping
	
	# Colisor de Sombra (BoxShape)
	if colisor_sombra.shape is BoxShape:
		colisor_sombra.shape.extents.x = comp_sombra / 2.0
		colisor_sombra.translation.x = comp_sombra / 2.0
		
	# Atualiza a imunidade do Conde se ele estiver na sombra
	if conde_ref != null and is_instance_valid(conde_ref):
		conde_ref.imune_ao_sol = true

func _on_AreaSombra_body_entered(body):
	if body.name == "Conde":
		conde_ref = body
		body.imune_ao_sol = true
		print("[Sombra] Conde entrou na área segura.")
		
		# Cura dinâmica de acordo com a fase: 15% na Fase 2 e 10% na Fase 3
		if not vida_recuperada:
			vida_recuperada = true
			var valor_cura = 15.0 if DadosJogo.fase_atual == 2 else 10.0
			body.energia_vital = min(100.0, body.energia_vital + valor_cura)
			var barra = body.get_node_or_null("HUD/BarraVida")
			if barra != null:
				barra.value = body.energia_vital
			print("[Sombra] Conde recebeu ", valor_cura, "% de cura de vida ancestral!")

func _on_AreaSombra_body_exited(body):
	if body.name == "Conde" and conde_ref == body:
		body.imune_ao_sol = false
		conde_ref = null
		print("[Sombra] Conde saiu da área segura.")

var _blocos_cache = null

func _is_custom_level() -> bool:
	var pai = get_parent()
	return pai != null and (pai.name.begins_with("LevelLoader") or pai.has_method("carregar_fase"))

# Retorna a lista de blocos de chão com [x_centro, y_superficie]
# Cada bloco de chão tem largura 30m (CubeMesh size.x=30), centrado no x_centro
# A superfície é y_centro + 0 (topo do cubo visualmente ajustado)
func _obter_blocos_chao():
	if _blocos_cache != null:
		return _blocos_cache
		
	var blocos = []
	
	if _is_custom_level():
		var pai = get_parent()
		if "dados_fase" in pai and "blocos" in pai.dados_fase:
			for bloco in pai.dados_fase.blocos:
				# Calcula a posição X e a altura da superfície Y (py + ESCALA/2.0)
				var px = (bloco.x / pai.BLOCO_PX) * pai.ESCALA
				var py = ((pai._max_y_px - bloco.y) / pai.BLOCO_PX) * pai.ESCALA
				var y_surf = py + (pai.ESCALA / 2.0)
				blocos.append([px, y_surf])
			_blocos_cache = blocos
			return blocos
			
	var fase = DadosJogo.fase_atual
	
	if fase == 2:
		# Fase 2: Chao1(X=0,Y=0) a Chao6(X=175,Y=0), Chao7-10(rebaixado Y=-2.5), Chao11-19(Y=0)
		for i in range(6):
			blocos.append([i * 35.0, 0.0])
		for i in range(4):
			blocos.append([210.0 + i * 35.0, -2.5])
		for i in range(9):
			blocos.append([350.0 + i * 35.0, 0.0])
	elif fase == 3:
		# Fase 3: Chao1-5(Y=0), Chao6-9(Y=2 elevado), Chao10-11(Y=0), Chao12-14(Y=-2.5), Chao15-23(Y=0)
		for i in range(5):
			blocos.append([i * 35.0, 0.0])
		for i in range(4):
			blocos.append([175.0 + i * 35.0, 2.0])
		for i in range(2):
			blocos.append([315.0 + i * 35.0, 0.0])
		for i in range(3):
			blocos.append([385.0 + i * 35.0, -2.5])
		for i in range(9):
			blocos.append([490.0 + i * 35.0, 0.0])
	else:
		# Fase 1 e genérica
		for i in range(10):
			blocos.append([i * 35.0, 0.0])
		blocos.append([350.0, 2.0])
		blocos.append([385.0, 4.0])
		blocos.append([420.0, 2.0])
		blocos.append([455.0, -2.0])
		for i in range(5):
			blocos.append([490.0 + i * 35.0, 0.0])
	
	_blocos_cache = blocos
	return blocos

func _obter_bloco_em(x_pos, pos_y = 999.0):
	# Retorna o bloco [x_centro, y_superficie] sob a posição X, escolhendo o mais alto se houver sobreposição (ex: colunas)
	var blocos = _obter_blocos_chao()
	# Usamos tolerância estendida de 3.0 para custom levels, garantindo detecção firme sob o pó/jogador
	var meia_largura = 3.0 if _is_custom_level() else 15.0
	var melhor_bloco = null
	var menor_dist = 9999.0
	for bloco in blocos:
		var x_centro = bloco[0]
		var x_min = x_centro - meia_largura
		var x_max = x_centro + meia_largura
		if x_pos >= x_min and x_pos <= x_max:
			var y_surf = bloco[1]
			# Ignora blocos que estão acima da semente/jogador (como o teto)
			if y_surf <= pos_y + 2.0:
				var dist = abs(x_pos - x_centro)
				if melhor_bloco == null:
					melhor_bloco = bloco
					menor_dist = dist
				else:
					# Escolhe o mais alto. Em caso de mesma altura, prefere o mais próximo horizontalmente.
					if abs(y_surf - melhor_bloco[1]) < 0.1:
						if dist < menor_dist:
							melhor_bloco = bloco
							menor_dist = dist
					elif y_surf > melhor_bloco[1]:
						melhor_bloco = bloco
						menor_dist = dist
	return melhor_bloco

func _esta_sobre_chao(x_pos):
	return _obter_bloco_em(x_pos, 999.0) != null

func _obter_altura_chao_em(x_pos, pos_y = 999.0):
	var bloco = _obter_bloco_em(x_pos, pos_y)
	if bloco != null:
		return bloco[1]
	return 0.0

func _obter_borda_chao_direita(x_pos):
	# Retorna a coordenada X da borda direita do chão contíguo com mesma altura
	# Percorre blocos adjacentes que estejam na mesma elevação (conectados sem vão)
	var bloco = _obter_bloco_em(x_pos, translation.y)
	if bloco == null:
		return x_pos + 5.0  # Fallback mínimo
	
	var custom = _is_custom_level()
	var meia_largura = 2.0 if custom else 15.0
	var passo_teste = 1.0 if custom else 2.5
	
	var altura_base = bloco[1]
	var borda = bloco[0] + meia_largura
	
	# Verifica se o próximo bloco (5m à direita da borda) está na mesma altura
	# Se sim, estende a borda para incluir esse bloco também
	for _i in range(100 if custom else 30):  # Máximo de 30 ou 100 blocos adjacentes
		var proximo = _obter_bloco_em(borda + passo_teste)  # Verifica passo_teste metros dentro do próximo bloco
		if proximo != null and abs(proximo[1] - altura_base) < 0.1:
			borda = proximo[0] + meia_largura  # Estende para a borda desse bloco
		else:
			break  # Vão ou elevação diferente, para aqui
	
	return borda

func _obter_x_chao_mais_proximo(x_pos):
	if _esta_sobre_chao(x_pos):
		return x_pos
		
	# Procura plataforma sólida mais próxima
	var limite = 60 if _is_custom_level() else 30
	for dist in range(1, limite):
		var dx = dist * 0.5
		# Testa esquerda
		if _esta_sobre_chao(x_pos - dx):
			return x_pos - dx
		# Testa direita
		if _esta_sobre_chao(x_pos + dx):
			return x_pos + dx
	return x_pos # Fallback se não achar plataforma
