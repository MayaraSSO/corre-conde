extends Control

# ===========================================================================
# EditorFases.gd — Editor de Fases Visual
# Cria/edita mapas no formato .lvl compatível com LevelLoader e jogo_comp1
#
# CONTROLES:
#   Clique Esquerdo = colocar bloco
#   Clique Direito  = apagar bloco
#   Teclas 0-9      = selecionar textura rápida
#   Ctrl+S          = salvar .lvl
#   Ctrl+L          = carregar .lvl
#   Ctrl+T          = testar fase no jogo
#   P               = modo posicionar jogador
#   O               = modo posicionar saída
#   Esc             = voltar ao menu
# ===========================================================================

const TAM_CELULA = 28  # Pixels na tela por célula do grid
const PX_LVL = 60      # Pixels no formato .lvl original

# Estado do grid
var grid = {}  # { Vector2(col, row) : int(textura_id) }
var objetos_grid = {}  # { Vector2(col, row) : String(tipo) }
var colunas = 32
var linhas = 18

# Posições especiais
var pos_jogador = Vector2(1, 15)  # grid coords
var pos_saida = Vector2(30, 15)   # grid coords

# Ferramentas
var textura_atual = 3
var modo = "pintar"  # "pintar", "jogador", "saida"

# Scroll
var camera_offset = Vector2(10, 10)

# Cores por ID
var CORES = {
	0: Color(0.12, 0.12, 0.12),
	1: Color(0.35, 0.25, 0.15),
	2: Color(0.45, 0.35, 0.20),
	3: Color(0.55, 0.45, 0.30),
	4: Color(0.08, 0.08, 0.08),
	5: Color(0.65, 0.55, 0.35),
	6: Color(0.40, 0.30, 0.20),
	7: Color(0.30, 0.30, 0.35),
	8: Color(0.50, 0.40, 0.30),
	9: Color(0.60, 0.50, 0.35),
	10: Color(0.50, 0.45, 0.35),
	11: Color(0.45, 0.40, 0.30),
	12: Color(0.70, 0.55, 0.25),
	13: Color(0.65, 0.50, 0.20),
	14: Color(0.60, 0.45, 0.20),
	15: Color(0.80, 0.70, 0.50),
	16: Color(0.75, 0.65, 0.45),
	17: Color(0.40, 0.35, 0.25),
	18: Color(0.25, 0.20, 0.15),
	19: Color(0.55, 0.50, 0.40),
	20: Color(0.20, 0.18, 0.15),
}

var NOMES = {
	0: "Preto", 1: "Terra", 2: "Terra2", 3: "Pedra", 4: "Escuro",
	5: "Areia", 6: "Madeira", 7: "Parede", 8: "Tijolo", 9: "Det.A",
	10: "Det.B", 11: "Det.C", 12: "Orn.A", 13: "Orn.B", 14: "Orn.C",
	15: "Teto", 16: "BordaS", 17: "Escada", 18: "Pilar", 19: "Deco",
	20: "Sombra"
}

func _ready():
	# Preenche bordas automaticamente para ter um mapa básico
	_criar_mapa_padrao()

func _criar_mapa_padrao():
	grid.clear()
	# Chão (linha de baixo)
	for x in range(colunas):
		grid[Vector2(x, linhas - 1)] = 1  # Terra
		grid[Vector2(x, linhas - 2)] = 2  # Terra2
	# Teto
	for x in range(colunas):
		grid[Vector2(x, 0)] = 7  # Parede
	# Paredes laterais
	for y in range(linhas):
		grid[Vector2(0, y)] = 7
		grid[Vector2(colunas - 1, y)] = 7
	# Algumas plataformas de exemplo
	for x in range(5, 10):
		grid[Vector2(x, 12)] = 8  # Plataforma de tijolo
	for x in range(15, 22):
		grid[Vector2(x, 10)] = 15  # Plataforma alta

func _process(_delta):
	update()  # Redesenha tudo

func _draw():
	# Fundo escuro
	draw_rect(Rect2(0, 0, rect_size.x, rect_size.y), Color(0.06, 0.06, 0.1), true)
	
	# Desenha blocos
	for pos in grid:
		var tex_id = grid[pos]
		var cor = CORES.get(tex_id, Color(1, 0, 1))
		var r = Rect2(
			camera_offset.x + pos.x * TAM_CELULA,
			camera_offset.y + pos.y * TAM_CELULA,
			TAM_CELULA - 1,
			TAM_CELULA - 1
		)
		draw_rect(r, cor, true)
	
	# Grade
	var cor_grade = Color(0.2, 0.2, 0.3, 0.3)
	for x in range(colunas + 1):
		var xp = camera_offset.x + x * TAM_CELULA
		draw_line(Vector2(xp, camera_offset.y), Vector2(xp, camera_offset.y + linhas * TAM_CELULA), cor_grade)
	for y in range(linhas + 1):
		var yp = camera_offset.y + y * TAM_CELULA
		draw_line(Vector2(camera_offset.x, yp), Vector2(camera_offset.x + colunas * TAM_CELULA, yp), cor_grade)
	
	# Jogador (P verde)
	var rp = Rect2(
		camera_offset.x + pos_jogador.x * TAM_CELULA,
		camera_offset.y + pos_jogador.y * TAM_CELULA,
		TAM_CELULA - 1, TAM_CELULA - 1
	)
	draw_rect(rp, Color(0.0, 1.0, 0.0, 0.8), true)
	draw_string(get_font("font", "Label"), rp.position + Vector2(6, 18), "P", Color(1, 1, 1))
	
	# Saída (S dourado)
	var rs = Rect2(
		camera_offset.x + pos_saida.x * TAM_CELULA,
		camera_offset.y + pos_saida.y * TAM_CELULA,
		TAM_CELULA - 1, TAM_CELULA - 1
	)
	draw_rect(rs, Color(1.0, 0.84, 0.0, 0.8), true)
	draw_string(get_font("font", "Label"), rs.position + Vector2(6, 18), "S", Color(1, 1, 1))
	
	# Desenha objetos (Lobo e Cruz) no grid
	for pos in objetos_grid:
		var tipo = objetos_grid[pos]
		var r_obj = Rect2(
			camera_offset.x + pos.x * TAM_CELULA + 2,
			camera_offset.y + pos.y * TAM_CELULA + 2,
			TAM_CELULA - 5,
			TAM_CELULA - 5
		)
		if tipo == "lobo":
			draw_rect(r_obj, Color(0.9, 0.2, 0.2, 0.8), true)
			draw_string(get_font("font", "Label"), r_obj.position + Vector2(6, 17), "L", Color(1, 1, 1))
		elif tipo == "cruz":
			draw_rect(r_obj, Color(0.2, 0.5, 0.9, 0.8), true)
			draw_string(get_font("font", "Label"), r_obj.position + Vector2(6, 17), "C", Color(1, 1, 1))
	
	# ---- HUD do Editor (parte inferior) ----
	var y_hud = rect_size.y - 80
	draw_rect(Rect2(0, y_hud, rect_size.x, 80), Color(0.1, 0.1, 0.15, 0.95), true)
	draw_line(Vector2(0, y_hud), Vector2(rect_size.x, y_hud), Color(0.3, 0.3, 0.4))
	
	# Paleta de texturas
	var x_paleta = 10
	for i in range(21):
		var cor_tex = CORES.get(i, Color(1, 0, 1))
		var r_pal = Rect2(x_paleta + i * 30, y_hud + 5, 26, 26)
		draw_rect(r_pal, cor_tex, true)
		if i == textura_atual:
			draw_rect(r_pal.grow(2), Color(1, 1, 1), false, 2.0)
		# Número da textura
		draw_string(get_font("font", "Label"), Vector2(x_paleta + i * 30 + 6, y_hud + 22), str(i), Color(1, 1, 1, 0.7))
	
	# Info do modo atual
	var texto_modo = "MODO: "
	match modo:
		"pintar": texto_modo += "PINTAR (tex %d: %s)" % [textura_atual, NOMES.get(textura_atual, "?")]
		"jogador": texto_modo += "POSICIONAR JOGADOR (clique)"
		"saida": texto_modo += "POSICIONAR SAÍDA (clique)"
		"lobo": texto_modo += "POSICIONAR LOBO (clique)"
		"cruz": texto_modo += "POSICIONAR CRUCIFIXO (clique)"
	draw_string(get_font("font", "Label"), Vector2(10, y_hud + 55), texto_modo, Color(1, 1, 1))
	
	# Atalhos
	var atalhos = "Ctrl+S=Salvar  Ctrl+L=Carregar  Ctrl+T=Testar  P=Jogador  O=Saída  L=Lobo  K=Cruz  0-9=Textura  Esc=Menu"
	draw_string(get_font("font", "Label"), Vector2(10, y_hud + 75), atalhos, Color(0.6, 0.6, 0.7))

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var pos_grid = _mouse_para_grid(event.position)
		
		if event.button_index == BUTTON_LEFT:
			# Checa clique na paleta de texturas primeiro (fora de _valido(pos_grid))
			var y_hud = rect_size.y - 80
			if event.position.y >= y_hud + 5 and event.position.y <= y_hud + 31:
				var idx = int((event.position.x - 10) / 30)
				if idx >= 0 and idx <= 20:
					textura_atual = idx
					modo = "pintar"
					return
			
			if _valido(pos_grid):
				match modo:
					"pintar":
						grid[pos_grid] = textura_atual
					"jogador":
						pos_jogador = pos_grid
						modo = "pintar"
					"saida":
						pos_saida = pos_grid
						modo = "pintar"
					"lobo":
						objetos_grid[pos_grid] = "lobo"
						modo = "pintar"
					"cruz":
						objetos_grid[pos_grid] = "cruz"
						modo = "pintar"
		
		elif event.button_index == BUTTON_RIGHT:
			if _valido(pos_grid):
				grid.erase(pos_grid)
				objetos_grid.erase(pos_grid)
	
	# Arrastar para pintar/apagar
	if event is InputEventMouseMotion:
		var pos_grid = _mouse_para_grid(event.position)
		if _valido(pos_grid):
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				match modo:
					"pintar":
						grid[pos_grid] = textura_atual
					"lobo":
						objetos_grid[pos_grid] = "lobo"
					"cruz":
						objetos_grid[pos_grid] = "cruz"
			elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
				grid.erase(pos_grid)
				objetos_grid.erase(pos_grid)

func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed):
		return
	
	match event.scancode:
		KEY_ESCAPE:
			get_tree().change_scene("res://MenuPrincipal.tscn")
		KEY_P:
			modo = "jogador"
		KEY_O:
			modo = "saida"
		KEY_L:
			if event.control:
				_carregar()
			else:
				modo = "lobo"
		KEY_K:
			modo = "cruz"
		KEY_S:
			if event.control:
				_salvar()
		KEY_T:
			if event.control:
				_testar()
		KEY_0, KEY_KP_0: textura_atual = 0
		KEY_1, KEY_KP_1: textura_atual = 1
		KEY_2, KEY_KP_2: textura_atual = 2
		KEY_3, KEY_KP_3: textura_atual = 3
		KEY_4, KEY_KP_4: textura_atual = 4
		KEY_5, KEY_KP_5: textura_atual = 5
		KEY_6, KEY_KP_6: textura_atual = 6
		KEY_7, KEY_KP_7: textura_atual = 7
		KEY_8, KEY_KP_8: textura_atual = 8
		KEY_9, KEY_KP_9: textura_atual = 9

func _mouse_para_grid(mouse_pos: Vector2) -> Vector2:
	var local = mouse_pos - camera_offset
	return Vector2(int(local.x / TAM_CELULA), int(local.y / TAM_CELULA))

func _valido(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < colunas and pos.y >= 0 and pos.y < linhas

# -----------------------------------------------------------------------
# SALVAR .lvl
# -----------------------------------------------------------------------
func _salvar():
	var dialog = FileDialog.new()
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.filters = PoolStringArray(["*.lvl ; Arquivo de Fase"])
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.connect("file_selected", self, "_ao_salvar")
	add_child(dialog)
	dialog.popup_centered(Vector2(700, 500))

func _ao_salvar(caminho: String):
	_escrever_lvl(caminho)
	print("[Editor] Salvo em: " + caminho)

func _escrever_lvl(caminho: String):
	var arq = File.new()
	if arq.open(caminho, File.WRITE) != OK:
		push_error("[Editor] Não foi possível salvar: " + caminho)
		return
	
	# Coleta blocos
	var blocos = []
	for pos in grid:
		blocos.append({"x": int(pos.x), "y": int(pos.y), "tex": grid[pos]})
		
	# Coleta objetos
	var objs = []
	for pos in objetos_grid:
		objs.append({"x": int(pos.x), "y": int(pos.y), "tipo": objetos_grid[pos]})
	
	# Texturas únicas
	var tex_set = {}
	for b in blocos:
		tex_set[b.tex] = true
	var tex_lista = tex_set.keys()
	tex_lista.sort()
	
	# Cabeçalho: [bg] [n_tex] [n_blocos] [n_coll] [n_trig] [n_obj] [n_texObj] [musica] [obj]
	arq.store_line("1 %d %d 0 0 %d 1 0 0" % [tex_lista.size(), blocos.size(), objs.size()])
	arq.store_line("")
	
	# Jogador
	arq.store_line("%d %d" % [int(pos_jogador.x) * PX_LVL, int(pos_jogador.y) * PX_LVL])
	arq.store_line("")
	
	# Saída
	arq.store_line("%d %d 2" % [int(pos_saida.x) * PX_LVL, int(pos_saida.y) * PX_LVL])
	arq.store_line("")
	
	# Texturas
	for tid in tex_lista:
		arq.store_line(str(tid))
	arq.store_line("")
	
	# Blocos
	for b in blocos:
		arq.store_line("%d %d %d" % [b.x * PX_LVL, b.y * PX_LVL, b.tex])
	arq.store_line("")
	
	# Colliders (vazio)
	arq.store_line("")
	
	# Triggers (vazio)
	arq.store_line("")
	
	# Objetos
	for o in objs:
		arq.store_line("%d %d %s" % [o.x * PX_LVL, o.y * PX_LVL, o.tipo])
	arq.store_line("")
	
	arq.close()

# -----------------------------------------------------------------------
# CARREGAR .lvl
# -----------------------------------------------------------------------
func _carregar():
	var dialog = FileDialog.new()
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.filters = PoolStringArray(["*.lvl ; Arquivo de Fase"])
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.connect("file_selected", self, "_ao_carregar")
	add_child(dialog)
	dialog.popup_centered(Vector2(700, 500))

func _ao_carregar(caminho: String):
	var arq = File.new()
	if arq.open(caminho, File.READ) != OK:
		push_error("[Editor] Não abriu: " + caminho)
		return
	
	var txt = arq.get_as_text()
	arq.close()
	var ls = txt.split("\n")
	var i = 0
	
	grid.clear()
	objetos_grid.clear()
	
	# Cabeçalho
	var r = _prox(ls, i); i = r[1]
	var t = r[0].split(" ")
	var n_tex = int(t[1])
	var n_blocos = int(t[2])
	var n_colliders = int(t[3]) if t.size() >= 4 else 0
	var n_triggers = int(t[4]) if t.size() >= 5 else 0
	var n_objetos = int(t[5]) if t.size() >= 6 else 0
	
	# Jogador
	r = _prox(ls, i); i = r[1]
	t = r[0].split(" ")
	pos_jogador = Vector2(int(float(t[0]) / PX_LVL), int(float(t[1]) / PX_LVL))
	
	# Saída
	r = _prox(ls, i); i = r[1]
	t = r[0].split(" ")
	pos_saida = Vector2(int(float(t[0]) / PX_LVL), int(float(t[1]) / PX_LVL))
	
	# Texturas (pula)
	for _j in range(n_tex):
		r = _prox(ls, i); i = r[1]
	
	# Blocos
	var max_x = 0
	var max_y = 0
	for _j in range(n_blocos):
		r = _prox(ls, i); i = r[1]
		t = r[0].split(" ")
		if t.size() >= 3:
			var gx = int(float(t[0]) / PX_LVL)
			var gy = int(float(t[1]) / PX_LVL)
			grid[Vector2(gx, gy)] = int(t[2])
			if gx > max_x: max_x = gx
			if gy > max_y: max_y = gy
			
	# Colliders (pula)
	for _j in range(n_colliders):
		r = _prox(ls, i); i = r[1]
		
	# Triggers (pula)
	for _j in range(n_triggers):
		r = _prox(ls, i); i = r[1]
		
	# Objetos
	for _j in range(n_objetos):
		r = _prox(ls, i); i = r[1]
		var ot = r[0].split(" ")
		if ot.size() >= 3:
			var ox = int(float(ot[0]) / PX_LVL)
			var oy = int(float(ot[1]) / PX_LVL)
			var tipo = ot[2].strip_edges()
			if tipo in ["lobo", "cruz"]:
				objetos_grid[Vector2(ox, oy)] = tipo
	
	colunas = max(max_x + 2, 20)
	linhas = max(max_y + 2, 12)
	
	print("[Editor] Carregado: %d blocos, grid %dx%d" % [n_blocos, colunas, linhas])

# -----------------------------------------------------------------------
# TESTAR no jogo
# -----------------------------------------------------------------------
func _testar():
	var caminho = "user://editor_teste.lvl"
	_escrever_lvl(caminho)
	
	DadosJogo.modo_editor = true
	DadosJogo.caminho_fase_custom = caminho
	get_tree().change_scene("res://FaseCarregada.tscn")

func _prox(ls: PoolStringArray, idx: int) -> Array:
	var j = idx
	while j < ls.size():
		var l = ls[j].strip_edges()
		j += 1
		if l != "":
			return [l, j]
	return ["", j]

# Callbacks dos botões (caso existam no .tscn)
func _on_BotaoSalvar_pressed(): _salvar()
func _on_BotaoCarregar_pressed(): _carregar()
func _on_BotaoTestar_pressed(): _testar()
func _on_BotaoVoltar_pressed(): get_tree().change_scene("res://MenuPrincipal.tscn")
