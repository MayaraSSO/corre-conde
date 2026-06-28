extends Spatial

# ===========================================================================
# LevelLoader.gd — Importador de Níveis do formato .lvl (jogo_comp1)
# Converte os dados 2D do editor em C para nós 3D do Godot (2.5D).
# CADA bloco gera um StaticBody com colisão para o jogador poder andar.
# ===========================================================================

const BLOCO_PX = 60.0
const ESCALA = 4.0  # 1 bloco = 4 unidades Godot (para compatibilidade física)

# Altura máxima do mapa (calculada na leitura) — usada para inverter Y
var _max_y_px = 0.0

# Materiais reutilizáveis (cache)
var _cache_materiais = {}

# Dados da fase carregada
var dados_fase = {}

var player_spawn_pos = Vector3.ZERO
var saida_spawn_pos = Vector3.ZERO

func _ready():
	dados_fase = _criar_dados_vazios()

func _criar_dados_vazios() -> Dictionary:
	return {
		"background_id": 0,
		"n_texturas": 0,
		"n_blocos": 0,
		"n_colliders": 0,
		"n_triggers": 0,
		"n_objetos": 0,
		"musica_id": 0,
		"objetivos": 0,
		"player_pos": Vector2.ZERO,
		"saida_pos": Vector2.ZERO,
		"saida_id": 0,
		"texturas_ids": [],
		"blocos": [],
		"colliders": [],
		"triggers": [],
		"objetos": []
	}

# -----------------------------------------------------------------------
# Função principal: carrega .lvl e instancia a fase 3D
# -----------------------------------------------------------------------
func carregar_fase(caminho_lvl: String) -> bool:
	var arquivo = File.new()
	if arquivo.open(caminho_lvl, File.READ) != OK:
		push_error("LevelLoader: ERRO ao abrir: " + caminho_lvl)
		return false
	
	# Limpar filhos anteriores
	for filho in get_children():
		filho.queue_free()
	
	var conteudo = arquivo.get_as_text()
	arquivo.close()
	
	var linhas = conteudo.split("\n")
	var idx = 0
	
	dados_fase = _criar_dados_vazios()
	
	# --- CABEÇALHO ---
	var r = _proxima(linhas, idx)
	idx = r[1]
	var t = r[0].split(" ")
	if t.size() < 9:
		push_error("LevelLoader: Cabeçalho inválido: " + r[0])
		return false
	
	dados_fase.background_id = int(t[0])
	dados_fase.n_texturas    = int(t[1])
	dados_fase.n_blocos      = int(t[2])
	dados_fase.n_colliders   = int(t[3])
	dados_fase.n_triggers    = int(t[4])
	dados_fase.n_objetos     = int(t[5])
	dados_fase.musica_id     = int(t[7])
	dados_fase.objetivos     = int(t[8])
	
	print("[LevelLoader] Cabeçalho: blocos=%d coll=%d trig=%d obj=%d" % [
		dados_fase.n_blocos, dados_fase.n_colliders,
		dados_fase.n_triggers, dados_fase.n_objetos])
	
	# --- POSIÇÃO DO JOGADOR ---
	r = _proxima(linhas, idx); idx = r[1]
	t = r[0].split(" ")
	dados_fase.player_pos = Vector2(float(t[0]), float(t[1]))
	print("[LevelLoader] Jogador: (%s, %s)" % [t[0], t[1]])
	
	# --- POSIÇÃO DA SAÍDA ---
	r = _proxima(linhas, idx); idx = r[1]
	t = r[0].split(" ")
	dados_fase.saida_pos = Vector2(float(t[0]), float(t[1]))
	dados_fase.saida_id = int(t[2]) if t.size() > 2 else 0
	print("[LevelLoader] Saída: (%s, %s)" % [t[0], t[1]])
	
	# --- IDs DE TEXTURAS ---
	for _i in range(dados_fase.n_texturas):
		r = _proxima(linhas, idx); idx = r[1]
		dados_fase.texturas_ids.append(int(r[0]))
	
	# --- BLOCOS (x, y, textura_idx) ---
	for _i in range(dados_fase.n_blocos):
		r = _proxima(linhas, idx); idx = r[1]
		t = r[0].split(" ")
		if t.size() >= 3:
			dados_fase.blocos.append({
				"x": float(t[0]),
				"y": float(t[1]),
				"tex": int(t[2])
			})
	
	# --- COLLIDERS (x, y, w, h) ---
	for _i in range(dados_fase.n_colliders):
		r = _proxima(linhas, idx); idx = r[1]
		t = r[0].split(" ")
		if t.size() >= 4:
			dados_fase.colliders.append({
				"x": float(t[0]),
				"y": float(t[1]),
				"w": float(t[2]),
				"h": float(t[3])
			})
	
	# --- TRIGGERS (x, y, w, h, func, param) ---
	for _i in range(dados_fase.n_triggers):
		r = _proxima(linhas, idx); idx = r[1]
		t = r[0].split(" ")
		if t.size() >= 6:
			dados_fase.triggers.append({
				"x": float(t[0]), "y": float(t[1]),
				"w": float(t[2]), "h": float(t[3]),
				"funcao": int(t[4]), "param": int(t[5])
			})
	
	# --- OBJETOS (x, y, tipo) ---
	for _i in range(dados_fase.n_objetos):
		r = _proxima(linhas, idx); idx = r[1]
		t = r[0].split(" ")
		if t.size() >= 3:
			dados_fase.objetos.append({
				"x": float(t[0]),
				"y": float(t[1]),
				"tipo": t[2]
			})
	
	# Calcular max_y para inverter coordenadas (chão fica em y=0, tudo positivo)
	_max_y_px = 0.0
	for bloco in dados_fase.blocos:
		if bloco.y > _max_y_px:
			_max_y_px = bloco.y
	print("[LevelLoader] max_y_px = %.0f" % _max_y_px)
	
	# Calcular coordenadas 3D para Conde e Saída
	var px = (dados_fase.player_pos.x / BLOCO_PX) * ESCALA
	var py = ((_max_y_px - dados_fase.player_pos.y) / BLOCO_PX) * ESCALA
	player_spawn_pos = Vector3(px, py + (ESCALA / 2.0) + 2.0, 0.0)
	
	var sx = (dados_fase.saida_pos.x / BLOCO_PX) * ESCALA
	var sy = ((_max_y_px - dados_fase.saida_pos.y) / BLOCO_PX) * ESCALA
	saida_spawn_pos = Vector3(sx, sy, 0.0)
	
	print("[LevelLoader] Parse OK! Construindo mundo 3D...")
	
	# Construir a geometria
	_construir_blocos()
	_construir_colliders_extras()
	_construir_saida()
	_construir_objetos()
	
	print("[LevelLoader] Fase pronta! %d blocos instanciados." % dados_fase.n_blocos)
	return true

# -----------------------------------------------------------------------
# Construir blocos 3D COM colisão
# -----------------------------------------------------------------------
func _construir_blocos():
	"""Cria um StaticBody com MeshInstance + CollisionShape para cada bloco."""
	for bloco in dados_fase.blocos:
		var body = StaticBody.new()
		
		# Mesh visual
		var mesh_inst = MeshInstance.new()
		var cubo = CubeMesh.new()
		cubo.size = Vector3(ESCALA, ESCALA, ESCALA * 2.0)  # Profundidade 2 para visual 2.5D
		mesh_inst.mesh = cubo
		mesh_inst.material_override = _material(bloco.tex)
		body.add_child(mesh_inst)
		
		# Colisão
		var col_shape = CollisionShape.new()
		var box = BoxShape.new()
		box.extents = Vector3(ESCALA / 2.0, ESCALA / 2.0, ESCALA)
		col_shape.shape = box
		body.add_child(col_shape)
		
		# Posição: converte pixels 2D para mundo 3D
		# No .lvl: Y cresce pra baixo. No Godot: Y cresce pra cima.
		# Usamos (max_y - y) para que o chão fique em y=0 (tudo positivo)
		var px = (bloco.x / BLOCO_PX) * ESCALA
		var py = ((_max_y_px - bloco.y) / BLOCO_PX) * ESCALA
		body.translation = Vector3(px, py, 0.0)
		body.name = "Bloco_%d_%d" % [int(bloco.x), int(bloco.y)]
		
		add_child(body)

# -----------------------------------------------------------------------
# Colliders extras do .lvl (paredes invisíveis, barreiras)
# -----------------------------------------------------------------------
func _construir_colliders_extras():
	"""Colliders adicionais definidos no .lvl (paredes invisíveis, limites)."""
	for col in dados_fase.colliders:
		var body = StaticBody.new()
		var shape_node = CollisionShape.new()
		var box = BoxShape.new()
		
		var w = (col.w / BLOCO_PX) * ESCALA
		var h = (col.h / BLOCO_PX) * ESCALA
		box.extents = Vector3(w / 2.0, h / 2.0, ESCALA)
		shape_node.shape = box
		body.add_child(shape_node)
		
		# Centro do retângulo
		var cx = ((col.x + col.w / 2.0) / BLOCO_PX) * ESCALA
		var cy = ((_max_y_px - (col.y + col.h / 2.0)) / BLOCO_PX) * ESCALA
		body.translation = Vector3(cx, cy, 0.0)
		body.name = "Collider_%d_%d" % [int(col.x), int(col.y)]
		
		add_child(body)

# -----------------------------------------------------------------------
# Saída da fase (portal dourado)
# -----------------------------------------------------------------------
func _construir_saida():
	var mesh = MeshInstance.new()
	var cubo = CubeMesh.new()
	cubo.size = Vector3(ESCALA * 0.8, ESCALA * 1.5, ESCALA * 0.8)
	mesh.mesh = cubo
	
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(1.0, 0.84, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.84, 0.0)
	mat.emission_energy = 0.8
	mesh.material_override = mat
	
	mesh.translation = saida_spawn_pos + Vector3(0.0, (ESCALA * 1.5) / 2.0, 0.0)
	mesh.name = "Saida"
	add_child(mesh)

# -----------------------------------------------------------------------
# Objetos dinâmicos (lâmpadas, caixas, lasers)
# -----------------------------------------------------------------------
func _construir_objetos():
	for obj in dados_fase.objetos:
		var ox = (obj.x / BLOCO_PX) * ESCALA
		var oy = ((_max_y_px - obj.y) / BLOCO_PX) * ESCALA
		var pos = Vector3(ox, oy, 0.0)
		
		match obj.tipo:
			"lampada", "poste":
				_criar_luz(pos, obj.tipo)
			"caixa":
				_criar_caixa(pos)
			"laserH":
				_criar_laser(pos)
			"baseObjChao":
				_criar_objetivo(pos)
			"lobo":
				_criar_lobo(pos)
			"cruz":
				_criar_cruz(pos)
			_:
				print("[LevelLoader] Objeto desconhecido: '%s'" % obj.tipo)

func _criar_lobo(pos: Vector3):
	var lobo_cena = load("res://LoboFase1.tscn")
	if lobo_cena != null:
		var lobo = lobo_cena.instance()
		# Ajusta para centralizar no bloco do grid
		lobo.translation = pos + Vector3(ESCALA / 2.0, (ESCALA / 2.0) + 0.1, 0.0)
		add_child(lobo)
		print("[LevelLoader] Lobo instanciado em fase customizada em: ", lobo.translation)

func _criar_cruz(pos: Vector3):
	var cruz_cena = load("res://Crucifixo.tscn")
	if cruz_cena != null:
		var cruz = cruz_cena.instance()
		# Ajusta para centralizar no bloco do grid (rente ao chão do bloco)
		cruz.translation = pos + Vector3(ESCALA / 2.0, ESCALA / 2.0, 0.0)
		add_child(cruz)
		print("[LevelLoader] Crucifixo instanciado em fase customizada em: ", cruz.translation)

func _criar_luz(pos: Vector3, tipo: String):
	var light = OmniLight.new()
	light.translation = pos + Vector3(ESCALA / 2.0, ESCALA / 2.0, ESCALA * 1.5)
	light.omni_range = ESCALA * 8.0
	light.light_color = Color(1.0, 0.9, 0.6)
	light.light_energy = 1.2
	light.name = "Luz_" + tipo + "_%d" % int(pos.x)
	add_child(light)
	
	# Esfera visual para a lâmpada
	var mesh = MeshInstance.new()
	var esfera = SphereMesh.new()
	esfera.radius = ESCALA * 0.15
	esfera.height = ESCALA * 0.3
	mesh.mesh = esfera
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(1.0, 0.95, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.5)
	mat.emission_energy = 2.0
	mesh.material_override = mat
	mesh.translation = pos + Vector3(ESCALA / 2.0, ESCALA / 2.0, ESCALA * 1.5)
	add_child(mesh)

func _criar_caixa(pos: Vector3):
	var body = KinematicBody.new()
	var mesh = MeshInstance.new()
	var cubo = CubeMesh.new()
	cubo.size = Vector3(ESCALA * 0.9, ESCALA * 0.9, ESCALA * 0.9)
	mesh.mesh = cubo
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(0.6, 0.4, 0.2)
	mesh.material_override = mat
	body.add_child(mesh)
	
	var col = CollisionShape.new()
	var box = BoxShape.new()
	box.extents = Vector3(ESCALA * 0.45, ESCALA * 0.45, ESCALA * 0.45)
	col.shape = box
	body.add_child(col)
	
	body.translation = pos
	body.name = "Caixa_%d" % int(pos.x)
	add_child(body)

func _criar_laser(pos: Vector3):
	var mesh = MeshInstance.new()
	var cubo = CubeMesh.new()
	cubo.size = Vector3(ESCALA, ESCALA * 0.08, ESCALA * 0.08)
	mesh.mesh = cubo
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(1.0, 0.0, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.0, 0.0)
	mat.emission_energy = 3.0
	mesh.material_override = mat
	mesh.translation = pos + Vector3(ESCALA / 2.0, ESCALA / 2.0, 0.0)
	mesh.name = "Laser_%d" % int(pos.x)
	add_child(mesh)

func _criar_objetivo(pos: Vector3):
	var mesh = MeshInstance.new()
	var cubo = CubeMesh.new()
	cubo.size = Vector3(ESCALA * 0.8, ESCALA * 0.8, ESCALA * 0.8)
	mesh.mesh = cubo
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(0.2, 0.8, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 0.2)
	mat.emission_energy = 0.5
	mesh.material_override = mat
	mesh.translation = pos
	mesh.name = "Objetivo_%d" % int(pos.x)
	add_child(mesh)

# -----------------------------------------------------------------------
# Materiais por ID de textura
# -----------------------------------------------------------------------
func _material(tex_id: int) -> SpatialMaterial:
	if _cache_materiais.has(tex_id):
		return _cache_materiais[tex_id]
	
	var mat = SpatialMaterial.new()
	match tex_id:
		0:  mat.albedo_color = Color(0.12, 0.12, 0.12)
		1:  mat.albedo_color = Color(0.35, 0.25, 0.15)
		2:  mat.albedo_color = Color(0.45, 0.35, 0.20)
		3:  mat.albedo_color = Color(0.55, 0.45, 0.30)
		4:  mat.albedo_color = Color(0.08, 0.08, 0.08)
		5:  mat.albedo_color = Color(0.65, 0.55, 0.35)
		6:  mat.albedo_color = Color(0.40, 0.30, 0.20)
		7:  mat.albedo_color = Color(0.30, 0.30, 0.35)
		8:  mat.albedo_color = Color(0.50, 0.40, 0.30)
		9:  mat.albedo_color = Color(0.60, 0.50, 0.35)
		10: mat.albedo_color = Color(0.50, 0.45, 0.35)
		11: mat.albedo_color = Color(0.45, 0.40, 0.30)
		12: mat.albedo_color = Color(0.70, 0.55, 0.25)
		13: mat.albedo_color = Color(0.65, 0.50, 0.20)
		14: mat.albedo_color = Color(0.60, 0.45, 0.20)
		15: mat.albedo_color = Color(0.80, 0.70, 0.50)
		16: mat.albedo_color = Color(0.75, 0.65, 0.45)
		17: mat.albedo_color = Color(0.40, 0.35, 0.25)
		18: mat.albedo_color = Color(0.25, 0.20, 0.15)
		19: mat.albedo_color = Color(0.55, 0.50, 0.40)
		20: mat.albedo_color = Color(0.20, 0.18, 0.15)
		_:  mat.albedo_color = Color(1.0, 0.0, 1.0)  # Magenta debug
	
	_cache_materiais[tex_id] = mat
	return mat

# -----------------------------------------------------------------------
# Utilitário: pula linhas vazias
# -----------------------------------------------------------------------
func _proxima(linhas: PoolStringArray, idx: int) -> Array:
	var i = idx
	while i < linhas.size():
		var l = linhas[i].strip_edges()
		i += 1
		if l != "":
			return [l, i]
	return ["", i]
