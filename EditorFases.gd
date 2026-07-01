extends Control

# ===========================================================================
# EditorFases.gd — Editor de Fases Visual Completo
# Cria/edita mapas no formato .lvl compatível com LevelLoader
#
# CONTROLES:
#   Clique Esquerdo   = colocar bloco/objeto
#   Clique Direito    = apagar bloco/objeto
#   Botão do Meio     = arrastar para mover o grid (pan)
#   Roda do Mouse     = zoom in/out
#   0-9               = selecionar textura rápida
#   P                 = modo posicionar jogador
#   O                 = modo posicionar saída
#   L                 = modo lobo
#   K                 = modo crucifixo
#   B                 = modo paladino (boss)
#   Q                 = modo caixão quebradiço
#   M                 = modo pó mágico
#   A                 = modo pedaço de anel
#   R                 = modo portal
#   I                 = modo lâmpada
#   X                 = modo caixa
#   G                 = modo preenchimento (flood fill)
#   F                 = trocar fundo (ciclar)
#   Ctrl+Setas        = redimensionar grid
#   Ctrl+S            = salvar .lvl
#   Ctrl+L            = carregar .lvl
#   Ctrl+T            = testar fase no jogo
#   Ctrl+Z            = desfazer
#   Ctrl+Y            = refazer
#   Esc               = voltar ao menu
# ===========================================================================

# --- Constantes ---
const PX_LVL = 60
const TAM_CEL_MIN = 12
const TAM_CEL_MAX = 40
const TAM_CEL_PADRAO = 28
const LARGURA_BARRA = 200
const ALTURA_STATUS = 32
const MAX_UNDO = 50
const MAX_FILL = 500

# --- Estado do grid ---
var grid = {}           # { Vector2(col, row) : int(textura_id) }
var objetos_grid = {}   # { Vector2(col, row) : String(tipo) }
var colunas = 32
var linhas = 18

# --- Posições especiais ---
var pos_jogador = Vector2(1, 15)
var pos_saida = Vector2(30, 15)

# --- Ferramentas ---
var textura_atual = 3
var modo = "pintar"    # pintar, fill, jogador, saida, lobo, cruz, paladino, caixao, po_magico, pedaco_anel, portal, lampada, caixa
var fundo_id = 0       # 0..4
var nome_fase = "Minha Fase"
var msg_status = ""     # Mensagem temporária na status bar
var msg_timer = 0.0

# --- Câmera/Scroll ---
var camera_offset = Vector2(210, 10)
var tam_celula = TAM_CEL_PADRAO
var is_panning = false
var pan_start = Vector2.ZERO
var offset_start = Vector2.ZERO
var is_painting = false

# --- Undo/Redo ---
var undo_stack = []
var redo_stack = []

# --- Mouse ---
var mouse_pos = Vector2.ZERO

# --- Cores por ID de textura ---
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

# --- Presets de fundo ---
var FUNDOS = [
	{"nome": "Noite Escura", "cor": Color(0.04, 0.04, 0.08)},
	{"nome": "Castelo", "cor": Color(0.10, 0.06, 0.12)},
	{"nome": "Floresta", "cor": Color(0.01, 0.05, 0.02)},
	{"nome": "Cemiterio", "cor": Color(0.04, 0.02, 0.06)},
	{"nome": "Lua Cheia", "cor": Color(0.05, 0.05, 0.10)},
]

# --- Informações dos objetos ---
var OBJETOS_INFO = [
	{"id": "lobo", "letra": "L", "cor": Color(0.9, 0.2, 0.2, 0.85), "nome": "Lobo"},
	{"id": "cruz", "letra": "C", "cor": Color(0.2, 0.5, 0.9, 0.85), "nome": "Crucifixo"},
	{"id": "paladino", "letra": "B", "cor": Color(0.7, 0.2, 0.8, 0.85), "nome": "Paladino"},
	{"id": "caixao", "letra": "Q", "cor": Color(0.45, 0.25, 0.15, 0.85), "nome": "Caixao"},
	{"id": "po_magico", "letra": "M", "cor": Color(0.2, 0.9, 0.3, 0.85), "nome": "Po Magico"},
	{"id": "pedaco_anel", "letra": "A", "cor": Color(1.0, 0.84, 0.0, 0.85), "nome": "P.Anel"},
	{"id": "portal", "letra": "R", "cor": Color(0.0, 0.9, 0.9, 0.85), "nome": "Portal"},
	{"id": "lampada", "letra": "I", "cor": Color(1.0, 0.95, 0.5, 0.85), "nome": "Lampada"},
	{"id": "caixa", "letra": "X", "cor": Color(0.6, 0.4, 0.2, 0.85), "nome": "Caixa"},
]

# Lookup rápido por tipo
var _obj_lookup = {}

# --- Layout da sidebar (calculado em _ready) ---
var _pal_y0 = 50
var _pal_cell = 28
var _pal_gap = 2
var _pal_cols = 5
var _pal_x0 = 10

var _obj_y0 = 0
var _obj_cell_w = 88
var _obj_cell_h = 22
var _obj_gap = 3
var _obj_x0 = 10

var _bg_y0 = 0
var _bg_cell_h = 20
var _bg_gap = 2
var _bg_x0 = 10
var _bg_w = 180

var _grid_y0 = 0

# =====================================================================
# INICIALIZAÇÃO
# =====================================================================
func _ready():
	# Monta lookup de objetos
	for info in OBJETOS_INFO:
		_obj_lookup[info.id] = info

	# Calcula layout da sidebar
	_pal_y0 = 80 # Ajustado para não colidir com o menu superior
	var pal_rows = int(ceil(21.0 / _pal_cols))
	_obj_y0 = _pal_y0 + pal_rows * (_pal_cell + _pal_gap) + 22
	var obj_rows = int(ceil(float(OBJETOS_INFO.size()) / 2.0))
	_bg_y0 = _obj_y0 + 14 + obj_rows * (_obj_cell_h + _obj_gap) + 18
	_grid_y0 = _bg_y0 + 14 + FUNDOS.size() * (_bg_cell_h + _bg_gap) + 18

	_criar_mapa_padrao()
	
	# Se há uma fase customizada para editar ou testar, carrega ela
	if DadosJogo.caminho_fase_custom != "":
		var f = File.new()
		if f.file_exists(DadosJogo.caminho_fase_custom):
			_ao_carregar(DadosJogo.caminho_fase_custom)
			# Se for a fase de teste temporária, reseta o caminho para não salvar por cima por engano
			if DadosJogo.caminho_fase_custom == "user://editor_teste.lvl":
				DadosJogo.caminho_fase_custom = ""
	
	# Cria a barra superior de botões
	call_deferred("_criar_interface_usuario")
	
	print("[Editor] Editor de Fases completo inicializado!")

func _criar_mapa_padrao():
	grid.clear()
	objetos_grid.clear()
	# Chão
	for x in range(colunas):
		grid[Vector2(x, linhas - 1)] = 1
		grid[Vector2(x, linhas - 2)] = 2
	# Teto
	for x in range(colunas):
		grid[Vector2(x, 0)] = 7
	# Paredes laterais
	for y in range(linhas):
		grid[Vector2(0, y)] = 7
		grid[Vector2(colunas - 1, y)] = 7
	# Plataformas de exemplo
	for x in range(5, 10):
		grid[Vector2(x, 12)] = 8
	for x in range(15, 22):
		grid[Vector2(x, 10)] = 15

func _process(delta):
	# Decrementa timer de mensagem
	if msg_timer > 0:
		msg_timer -= delta
		if msg_timer <= 0:
			msg_status = ""
	update()

# =====================================================================
# DESENHO PRINCIPAL
# =====================================================================
func _draw():
	var font = get_font("font", "Label")

	# --- Fundo da área do grid ---
	var cor_fundo = FUNDOS[fundo_id].cor if fundo_id < FUNDOS.size() else Color(0.06, 0.06, 0.1)
	draw_rect(Rect2(LARGURA_BARRA, 40, rect_size.x - LARGURA_BARRA, rect_size.y - 40 - ALTURA_STATUS), cor_fundo, true)

	# --- Blocos ---
	for pos in grid:
		var tex_id = grid[pos]
		var cor = CORES.get(tex_id, Color(1, 0, 1))
		var rx = camera_offset.x + pos.x * tam_celula
		var ry = camera_offset.y + pos.y * tam_celula
		if rx + tam_celula < LARGURA_BARRA or rx > rect_size.x:
			continue
		if ry + tam_celula < 40 or ry > rect_size.y - ALTURA_STATUS:
			continue
		draw_rect(Rect2(rx, ry, tam_celula - 1, tam_celula - 1), cor, true)

	# --- Grade ---
	var cor_grade = Color(0.25, 0.25, 0.35, 0.25)
	var grid_left = max(camera_offset.x, LARGURA_BARRA)
	var grid_right = min(camera_offset.x + colunas * tam_celula, rect_size.x)
	var grid_top = max(camera_offset.y, 40.0)
	var grid_bottom = min(camera_offset.y + linhas * tam_celula, rect_size.y - ALTURA_STATUS)

	for x in range(colunas + 1):
		var xp = camera_offset.x + x * tam_celula
		if xp >= LARGURA_BARRA and xp <= rect_size.x:
			draw_line(Vector2(xp, grid_top), Vector2(xp, grid_bottom), cor_grade)
	for y in range(linhas + 1):
		var yp = camera_offset.y + y * tam_celula
		if yp >= 40 and yp <= rect_size.y - ALTURA_STATUS:
			draw_line(Vector2(grid_left, yp), Vector2(grid_right, yp), cor_grade)

	# --- Jogador (P verde) ---
	var pjx = camera_offset.x + pos_jogador.x * tam_celula
	var pjy = camera_offset.y + pos_jogador.y * tam_celula
	if pjy >= 40 and pjy + tam_celula <= rect_size.y - ALTURA_STATUS:
		draw_rect(Rect2(pjx, pjy, tam_celula - 1, tam_celula - 1), Color(0.0, 1.0, 0.0, 0.8), true)
		if tam_celula >= 16:
			draw_string(font, Vector2(pjx + tam_celula * 0.2, pjy + tam_celula * 0.7), "P", Color(1, 1, 1))

	# --- Saída (S dourado) ---
	var psx = camera_offset.x + pos_saida.x * tam_celula
	var psy = camera_offset.y + pos_saida.y * tam_celula
	if psy >= 40 and psy + tam_celula <= rect_size.y - ALTURA_STATUS:
		draw_rect(Rect2(psx, psy, tam_celula - 1, tam_celula - 1), Color(1.0, 0.84, 0.0, 0.8), true)
		if tam_celula >= 16:
			draw_string(font, Vector2(psx + tam_celula * 0.2, psy + tam_celula * 0.7), "S", Color(1, 1, 1))

	# --- Objetos ---
	for pos in objetos_grid:
		var tipo = objetos_grid[pos]
		var info = _obj_lookup.get(tipo, null)
		if info == null:
			continue
		var ox = camera_offset.x + pos.x * tam_celula + 2
		var oy = camera_offset.y + pos.y * tam_celula + 2
		if ox + tam_celula < LARGURA_BARRA or ox > rect_size.x:
			continue
		if oy + tam_celula < 40 or oy > rect_size.y - ALTURA_STATUS:
			continue
		draw_rect(Rect2(ox, oy, tam_celula - 5, tam_celula - 5), info.cor, true)
		if tam_celula >= 16:
			draw_string(font, Vector2(ox + tam_celula * 0.1, oy + tam_celula * 0.55), info.letra, Color(1, 1, 1))

	# --- Cursor do grid (hover) ---
	var gp = _mouse_para_grid(mouse_pos)
	if _valido(gp) and mouse_pos.x > LARGURA_BARRA and mouse_pos.y >= 40 and mouse_pos.y < rect_size.y - ALTURA_STATUS:
		var cx = camera_offset.x + gp.x * tam_celula
		var cy = camera_offset.y + gp.y * tam_celula
		var cor_cursor = Color(1, 1, 1, 0.35)
		if modo == "fill":
			cor_cursor = Color(0, 1, 1, 0.4)
		elif modo != "pintar":
			cor_cursor = Color(1, 1, 0, 0.35)
		draw_rect(Rect2(cx, cy, tam_celula - 1, tam_celula - 1), cor_cursor, false, 2.0)

	# --- Sidebar e Statusbar ---
	_draw_sidebar(font)
	_draw_statusbar(font)

# =====================================================================
# SIDEBAR (barra lateral esquerda)
# =====================================================================
func _draw_sidebar(font: Font):
	# Fundo
	draw_rect(Rect2(0, 40, LARGURA_BARRA, rect_size.y - 40), Color(0.08, 0.08, 0.12, 0.97), true)
	draw_line(Vector2(LARGURA_BARRA, 40), Vector2(LARGURA_BARRA, rect_size.y), Color(0.3, 0.3, 0.4))

	# Título da paleta
	draw_string(font, Vector2(10, 58), "PALETA DE TEXTURAS", Color(0.95, 0.88, 0.55))
	draw_line(Vector2(5, 64), Vector2(LARGURA_BARRA - 5, 64), Color(0.3, 0.3, 0.4))

	# ---- BLOCOS ----
	for i in range(21):
		var col = i % _pal_cols
		var row = int(i / _pal_cols)
		var px = _pal_x0 + col * (_pal_cell + _pal_gap)
		var py = _pal_y0 + row * (_pal_cell + _pal_gap)
		var cor = CORES.get(i, Color(1, 0, 1))
		var r = Rect2(px, py, _pal_cell, _pal_cell)
		draw_rect(r, cor, true)
		# Borda de seleção
		if i == textura_atual and (modo == "pintar" or modo == "fill"):
			draw_rect(r.grow(2), Color(1, 1, 1), false, 2.0)
		# Número da textura
		if _pal_cell >= 22:
			draw_string(font, Vector2(px + 2, py + _pal_cell - 5), str(i), Color(1, 1, 1, 0.55))

	# Separador
	var sep1 = _obj_y0 - 8
	draw_line(Vector2(5, sep1), Vector2(LARGURA_BARRA - 5, sep1), Color(0.3, 0.3, 0.4))

	# ---- OBJETOS ----
	draw_string(font, Vector2(10, _obj_y0), "OBJETOS", Color(0.7, 0.7, 0.8))
	for i in range(OBJETOS_INFO.size()):
		var info = OBJETOS_INFO[i]
		var col = i % 2
		var row = int(i / 2)
		var px = _obj_x0 + col * (_obj_cell_w + 4)
		var py = _obj_y0 + 14 + row * (_obj_cell_h + _obj_gap)
		var r = Rect2(px, py, _obj_cell_w, _obj_cell_h)
		# Fundo do botão
		var cor_btn = info.cor
		if modo == info.id:
			draw_rect(r.grow(1), Color(1, 1, 1), false, 2.0)
			cor_btn.a = 1.0
		draw_rect(r, cor_btn, true)
		# Texto
		draw_string(font, Vector2(px + 3, py + 15), info.letra + " " + info.nome, Color(1, 1, 1))

	# Separador
	var sep2 = _bg_y0 - 8
	draw_line(Vector2(5, sep2), Vector2(LARGURA_BARRA - 5, sep2), Color(0.3, 0.3, 0.4))

	# ---- FUNDO ----
	draw_string(font, Vector2(10, _bg_y0), "FUNDO (F)", Color(0.7, 0.7, 0.8))
	for i in range(FUNDOS.size()):
		var f = FUNDOS[i]
		var py = _bg_y0 + 14 + i * (_bg_cell_h + _bg_gap)
		var r = Rect2(_bg_x0, py, _bg_w, _bg_cell_h)
		draw_rect(r, f.cor.lightened(0.15), true)
		if i == fundo_id:
			draw_rect(r.grow(1), Color(1, 1, 1), false, 2.0)
		draw_string(font, Vector2(_bg_x0 + 5, py + 14), str(i) + ": " + f.nome, Color(1, 1, 1, 0.9))

	# Separador
	var sep3 = _grid_y0 - 8
	draw_line(Vector2(5, sep3), Vector2(LARGURA_BARRA - 5, sep3), Color(0.3, 0.3, 0.4))

	# ---- GRID INFO ----
	draw_string(font, Vector2(10, _grid_y0), "GRID", Color(0.7, 0.7, 0.8))
	draw_string(font, Vector2(10, _grid_y0 + 16), "%d x %d" % [colunas, linhas], Color(1, 1, 1))
	draw_string(font, Vector2(80, _grid_y0 + 16), "Ctrl+Setas", Color(0.5, 0.5, 0.6))
	draw_string(font, Vector2(10, _grid_y0 + 34), "Undo:%d Redo:%d" % [undo_stack.size(), redo_stack.size()], Color(0.5, 0.5, 0.6))
	draw_string(font, Vector2(10, _grid_y0 + 50), "Zoom: %d%%" % [int(float(tam_celula) / TAM_CEL_PADRAO * 100)], Color(0.5, 0.5, 0.6))

# =====================================================================
# STATUS BAR (barra inferior)
# =====================================================================
func _draw_statusbar(font: Font):
	var y = rect_size.y - ALTURA_STATUS
	draw_rect(Rect2(0, y, rect_size.x, ALTURA_STATUS), Color(0.1, 0.1, 0.15, 0.97), true)
	draw_line(Vector2(0, y), Vector2(rect_size.x, y), Color(0.3, 0.3, 0.4))

	# Modo atual
	var texto_modo = "MODO: "
	match modo:
		"pintar":
			texto_modo += "PINTAR [%d: %s]" % [textura_atual, NOMES.get(textura_atual, "?")]
		"fill":
			texto_modo += "PREENCHER [%d: %s]" % [textura_atual, NOMES.get(textura_atual, "?")]
		"jogador":
			texto_modo += "JOGADOR (clique no grid)"
		"saida":
			texto_modo += "SAIDA (clique no grid)"
		_:
			var info = _obj_lookup.get(modo, null)
			if info:
				texto_modo += info.nome.to_upper() + " (clique no grid)"
			else:
				texto_modo += modo.to_upper()
	draw_string(font, Vector2(10, y + 13), texto_modo, Color(1, 1, 1))

	# Coordenadas do mouse no grid
	var gp = _mouse_para_grid(mouse_pos)
	if _valido(gp) and mouse_pos.x > LARGURA_BARRA:
		var coord = "Celula: (%d, %d)" % [int(gp.x), int(gp.y)]
		draw_string(font, Vector2(rect_size.x * 0.45, y + 13), coord, Color(0.7, 0.7, 0.8))

	# Nome da fase
	draw_string(font, Vector2(rect_size.x * 0.7, y + 13), nome_fase, Color(0.6, 0.8, 0.6))

	# Mensagem de status ou atalhos
	if msg_status != "":
		draw_string(font, Vector2(10, y + 27), msg_status, Color(0.4, 1.0, 0.4))
	else:
		draw_string(font, Vector2(10, y + 27), "G=Fill  F=Fundo  Ctrl+S/L/T  Ctrl+Z/Y  Esc=Menu", Color(0.45, 0.45, 0.55))

# =====================================================================
# INPUT — GUI (mouse dentro do Control)
# =====================================================================
func _gui_input(event):
	# --- Roda do mouse: Zoom ---
	if event is InputEventMouseButton and event.pressed:
		if event.position.x > LARGURA_BARRA and event.position.y >= 40 and event.position.y < rect_size.y - ALTURA_STATUS:
			if event.button_index == BUTTON_WHEEL_UP:
				_zoom(2, event.position)
				return
			elif event.button_index == BUTTON_WHEEL_DOWN:
				_zoom(-2, event.position)
				return
 
	# --- Botão do meio: Pan ---
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_MIDDLE:
			if event.pressed:
				if event.position.x > LARGURA_BARRA and event.position.y >= 40:
					is_panning = true
					pan_start = event.position
					offset_start = camera_offset
			else:
				is_panning = false
			return
 
	# --- Movimento do mouse ---
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		if is_panning:
			camera_offset = offset_start + (event.position - pan_start)
			return
		# Arrastar para pintar/apagar
		if event.position.x > LARGURA_BARRA and event.position.y >= 40 and event.position.y < rect_size.y - ALTURA_STATUS:
			var pos_grid = _mouse_para_grid(event.position)
			if _valido(pos_grid) and is_painting:
				if Input.is_mouse_button_pressed(BUTTON_LEFT) and modo == "pintar":
					grid[pos_grid] = textura_atual
				elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
					grid.erase(pos_grid)
					objetos_grid.erase(pos_grid)
		return
 
	# --- Clique esquerdo ---
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			# Clique na barra superior (toolbar)
			if event.position.y < 40:
				return
			# Clique na sidebar
			if event.position.x < LARGURA_BARRA:
				_handle_sidebar_click(event.position)
				return
			# Clique no grid
			if event.position.y >= rect_size.y - ALTURA_STATUS:
				return
			var pos_grid = _mouse_para_grid(event.position)
			if _valido(pos_grid):
				match modo:
					"pintar":
						if not is_painting:
							_salvar_undo()
							is_painting = true
						grid[pos_grid] = textura_atual
					"fill":
						_salvar_undo()
						_flood_fill(pos_grid)
					"jogador":
						_salvar_undo()
						pos_jogador = pos_grid
						modo = "pintar"
					"saida":
						_salvar_undo()
						pos_saida = pos_grid
						modo = "pintar"
					_:
						# Modo de objeto
						if _obj_lookup.has(modo):
							_salvar_undo()
							objetos_grid[pos_grid] = modo
							# Não reseta o modo — permite colocar vários seguidos
		else:
			is_painting = false
		return
 
	# --- Clique direito: Apagar ---
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT:
		if event.pressed:
			if event.position.y < 40:
				return
			if event.position.x > LARGURA_BARRA and event.position.y < rect_size.y - ALTURA_STATUS:
				var pos_grid = _mouse_para_grid(event.position)
				if _valido(pos_grid):
					if not is_painting:
						_salvar_undo()
						is_painting = true
					grid.erase(pos_grid)
					objetos_grid.erase(pos_grid)
		else:
			is_painting = false
		return

# =====================================================================
# CLIQUE NA SIDEBAR
# =====================================================================
func _handle_sidebar_click(pos: Vector2):
	# Checa paleta de texturas
	for i in range(21):
		var col = i % _pal_cols
		var row = int(i / _pal_cols)
		var px = _pal_x0 + col * (_pal_cell + _pal_gap)
		var py = _pal_y0 + row * (_pal_cell + _pal_gap)
		if Rect2(px, py, _pal_cell, _pal_cell).has_point(pos):
			textura_atual = i
			modo = "pintar"
			return

	# Checa botões de objetos
	for i in range(OBJETOS_INFO.size()):
		var info = OBJETOS_INFO[i]
		var col = i % 2
		var row = int(i / 2)
		var px = _obj_x0 + col * (_obj_cell_w + 4)
		var py = _obj_y0 + 14 + row * (_obj_cell_h + _obj_gap)
		if Rect2(px, py, _obj_cell_w, _obj_cell_h).has_point(pos):
			modo = info.id
			return

	# Checa seletor de fundo
	for i in range(FUNDOS.size()):
		var py = _bg_y0 + 14 + i * (_bg_cell_h + _bg_gap)
		if Rect2(_bg_x0, py, _bg_w, _bg_cell_h).has_point(pos):
			fundo_id = i
			return

# =====================================================================
# ZOOM
# =====================================================================
func _zoom(delta: int, pos_mouse: Vector2):
	var old_tam = tam_celula
	tam_celula = int(clamp(tam_celula + delta, TAM_CEL_MIN, TAM_CEL_MAX))
	if tam_celula == old_tam:
		return
	# Zoom centrado na posição do mouse
	var grid_sob_mouse = (pos_mouse - camera_offset) / float(old_tam)
	camera_offset = pos_mouse - grid_sob_mouse * tam_celula

# =====================================================================
# INPUT — TECLADO (não consumido pelo _gui_input)
# =====================================================================
func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed):
		return

	# --- Ctrl + tecla ---
	if event.control:
		match event.scancode:
			KEY_S:
				_salvar()
			KEY_L:
				_carregar()
			KEY_T:
				_testar()
			KEY_Z:
				_undo()
			KEY_Y:
				_redo()
			KEY_RIGHT:
				colunas = min(colunas + 1, 200)
			KEY_LEFT:
				colunas = max(colunas - 1, 16)
			KEY_UP:
				linhas = max(linhas - 1, 10)
			KEY_DOWN:
				linhas = min(linhas + 1, 50)
		return

	# --- Teclas simples ---
	match event.scancode:
		KEY_ESCAPE:
			_voltar_ao_menu()
		KEY_P:
			modo = "jogador"
		KEY_O:
			modo = "saida"
		KEY_L:
			modo = "lobo"
		KEY_K:
			modo = "cruz"
		KEY_B:
			modo = "paladino"
		KEY_Q:
			modo = "caixao"
		KEY_M:
			modo = "po_magico"
		KEY_A:
			modo = "pedaco_anel"
		KEY_R:
			modo = "portal"
		KEY_I:
			modo = "lampada"
		KEY_X:
			modo = "caixa"
		KEY_G:
			modo = "fill"
		KEY_F:
			fundo_id = (fundo_id + 1) % FUNDOS.size()
		KEY_0, KEY_KP_0:
			textura_atual = 0; modo = "pintar"
		KEY_1, KEY_KP_1:
			textura_atual = 1; modo = "pintar"
		KEY_2, KEY_KP_2:
			textura_atual = 2; modo = "pintar"
		KEY_3, KEY_KP_3:
			textura_atual = 3; modo = "pintar"
		KEY_4, KEY_KP_4:
			textura_atual = 4; modo = "pintar"
		KEY_5, KEY_KP_5:
			textura_atual = 5; modo = "pintar"
		KEY_6, KEY_KP_6:
			textura_atual = 6; modo = "pintar"
		KEY_7, KEY_KP_7:
			textura_atual = 7; modo = "pintar"
		KEY_8, KEY_KP_8:
			textura_atual = 8; modo = "pintar"
		KEY_9, KEY_KP_9:
			textura_atual = 9; modo = "pintar"

# =====================================================================
# UTILITÁRIOS
# =====================================================================
func _mouse_para_grid(pos_mouse: Vector2) -> Vector2:
	var local = pos_mouse - camera_offset
	return Vector2(int(floor(local.x / tam_celula)), int(floor(local.y / tam_celula)))

func _valido(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < colunas and pos.y >= 0 and pos.y < linhas

# =====================================================================
# FLOOD FILL (Preenchimento)
# =====================================================================
func _flood_fill(inicio: Vector2):
	var alvo = grid.get(inicio, -1)  # -1 = célula vazia
	if alvo == textura_atual and alvo != -1:
		return  # Mesma textura, nada a fazer

	var fila = [inicio]
	var visitados = {}
	var preenchidos = 0

	while fila.size() > 0 and preenchidos < MAX_FILL:
		var pos = fila.pop_front()
		if visitados.has(pos):
			continue
		if not _valido(pos):
			continue

		var tex_aqui = grid.get(pos, -1)
		if tex_aqui != alvo:
			continue

		visitados[pos] = true
		grid[pos] = textura_atual
		preenchidos += 1

		fila.append(Vector2(pos.x + 1, pos.y))
		fila.append(Vector2(pos.x - 1, pos.y))
		fila.append(Vector2(pos.x, pos.y + 1))
		fila.append(Vector2(pos.x, pos.y - 1))

	print("[Editor] Fill: %d celulas preenchidas" % preenchidos)

# =====================================================================
# UNDO / REDO
# =====================================================================
func _salvar_undo():
	var snapshot = {
		"grid": grid.duplicate(),
		"objetos": objetos_grid.duplicate(),
		"pos_jogador": pos_jogador,
		"pos_saida": pos_saida,
		"fundo_id": fundo_id,
	}
	undo_stack.append(snapshot)
	if undo_stack.size() > MAX_UNDO:
		undo_stack.pop_front()
	redo_stack.clear()

func _undo():
	if undo_stack.size() == 0:
		return
	redo_stack.append({
		"grid": grid.duplicate(),
		"objetos": objetos_grid.duplicate(),
		"pos_jogador": pos_jogador,
		"pos_saida": pos_saida,
		"fundo_id": fundo_id,
	})
	var anterior = undo_stack.pop_back()
	grid = anterior.grid
	objetos_grid = anterior.objetos
	pos_jogador = anterior.pos_jogador
	pos_saida = anterior.pos_saida
	fundo_id = anterior.fundo_id
	print("[Editor] Undo (%d restantes)" % undo_stack.size())

func _redo():
	if redo_stack.size() == 0:
		return
	undo_stack.append({
		"grid": grid.duplicate(),
		"objetos": objetos_grid.duplicate(),
		"pos_jogador": pos_jogador,
		"pos_saida": pos_saida,
		"fundo_id": fundo_id,
	})
	var proximo = redo_stack.pop_back()
	grid = proximo.grid
	objetos_grid = proximo.objetos
	pos_jogador = proximo.pos_jogador
	pos_saida = proximo.pos_saida
	fundo_id = proximo.fundo_id
	print("[Editor] Redo (%d restantes)" % redo_stack.size())

# =====================================================================
# SALVAR .lvl (na coleção user://fases_custom/)
# =====================================================================
func _salvar():
	# Mostra popup para escolher o nome da fase
	var popup = ConfirmationDialog.new()
	popup.window_title = "Salvar Fase"
	popup.dialog_text = "\nDigite o nome da fase:"
	popup.rect_min_size = Vector2(360, 130)
	
	var campo = LineEdit.new()
	campo.name = "CampoNome"
	campo.text = nome_fase
	campo.max_length = 30
	campo.rect_min_size = Vector2(320, 30)
	campo.select_all_on_focus = true
	
	popup.add_child(campo)
	popup.register_text_enter(campo)
	popup.connect("confirmed", self, "_ao_confirmar_salvar", [campo])
	popup.connect("popup_hide", popup, "queue_free")
	
	add_child(popup)
	popup.popup_centered()
	campo.grab_focus()

func _ao_confirmar_salvar(campo: LineEdit):
	var nome_digitado = campo.text.strip_edges()
	if nome_digitado == "":
		nome_digitado = "Fase_Sem_Nome"
	nome_fase = nome_digitado
	
	# Sanitiza o nome para ser usado como arquivo
	var nome_arquivo = nome_digitado.replace(" ", "_").replace("/", "_").replace("\\", "_").replace(":", "_")
	
	# Cria o diretório se não existir
	var dir = Directory.new()
	if not dir.dir_exists("user://fases_custom"):
		dir.make_dir("user://fases_custom")
	
	var caminho = "user://fases_custom/" + nome_arquivo + ".lvl"
	_escrever_lvl(caminho)
	
	msg_status = "Fase salva: " + nome_digitado
	msg_timer = 3.0
	print("[Editor] Salvo em: " + caminho)

func _escrever_lvl(caminho: String):
	var arq = File.new()
	if arq.open(caminho, File.WRITE) != OK:
		push_error("[Editor] Nao foi possivel salvar: " + caminho)
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

	# Cabeçalho: [bg] [n_tex] [n_blocos] [n_coll] [n_trig] [n_obj] [n_texObj] [musica] [objetivos]
	arq.store_line("%d %d %d 0 0 %d 1 0 0" % [fundo_id, tex_lista.size(), blocos.size(), objs.size()])
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

# =====================================================================
# CARREGAR .lvl
# =====================================================================
func _carregar():
	var dialog = FileDialog.new()
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.filters = PoolStringArray(["*.lvl ; Arquivo de Fase"])
	dialog.access = FileDialog.ACCESS_USERDATA
	dialog.current_dir = "user://fases_custom"
	dialog.connect("file_selected", self, "_ao_carregar")
	add_child(dialog)
	dialog.popup_centered(Vector2(700, 500))

func _ao_carregar(caminho: String):
	var arq = File.new()
	if arq.open(caminho, File.READ) != OK:
		push_error("[Editor] Nao abriu: " + caminho)
		return

	_salvar_undo()

	var file_name = caminho.get_file().replace(".lvl", "").replace("_", " ")
	if file_name != "editor_teste":
		nome_fase = file_name

	var txt = arq.get_as_text()
	arq.close()
	var ls = txt.split("\n")
	var i = 0

	grid.clear()
	objetos_grid.clear()

	# Cabeçalho
	var r = _prox(ls, i); i = r[1]
	var t = r[0].split(" ")
	fundo_id = int(t[0]) if t.size() >= 1 else 0
	var n_tex = int(t[1]) if t.size() >= 2 else 0
	var n_blocos = int(t[2]) if t.size() >= 3 else 0
	var n_colliders = int(t[3]) if t.size() >= 4 else 0
	var n_triggers = int(t[4]) if t.size() >= 5 else 0
	var n_objetos = int(t[5]) if t.size() >= 6 else 0

	# Jogador
	r = _prox(ls, i); i = r[1]
	t = r[0].split(" ")
	if t.size() >= 2:
		pos_jogador = Vector2(int(float(t[0]) / PX_LVL), int(float(t[1]) / PX_LVL))

	# Saída
	r = _prox(ls, i); i = r[1]
	t = r[0].split(" ")
	if t.size() >= 2:
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
	var tipos_validos = ["lobo", "cruz", "paladino", "caixao", "po_magico", "pedaco_anel", "portal", "lampada", "caixa"]
	for _j in range(n_objetos):
		r = _prox(ls, i); i = r[1]
		var ot = r[0].split(" ")
		if ot.size() >= 3:
			var ox = int(float(ot[0]) / PX_LVL)
			var oy = int(float(ot[1]) / PX_LVL)
			var tipo = ot[2].strip_edges()
			if tipo in tipos_validos:
				objetos_grid[Vector2(ox, oy)] = tipo

	colunas = max(max_x + 2, 20)
	linhas = max(max_y + 2, 12)

	# Valida fundo_id
	if fundo_id < 0 or fundo_id >= FUNDOS.size():
		fundo_id = 0

	print("[Editor] Carregado: %d blocos, %d objetos, grid %dx%d, fundo=%d" % [n_blocos, n_objetos, colunas, linhas, fundo_id])

# =====================================================================
# TESTAR NO JOGO
# =====================================================================
func _testar():
	var caminho = "user://editor_teste.lvl"
	_escrever_lvl(caminho)

	DadosJogo.modo_editor = true
	DadosJogo.caminho_fase_custom = caminho
	get_tree().change_scene("res://FaseCarregada.tscn")

# =====================================================================
# UTILITÁRIO INTERNO
# =====================================================================
func _prox(ls: PoolStringArray, idx: int) -> Array:
	var j = idx
	while j < ls.size():
		var l = ls[j].strip_edges()
		j += 1
		if l != "":
			return [l, j]
	return ["", j]

func _voltar_ao_menu():
	if DadosJogo.caminho_fase_custom != "" and DadosJogo.caminho_fase_custom != "user://editor_teste.lvl":
		get_tree().change_scene("res://MenuFasesCustom.tscn")
	else:
		get_tree().change_scene("res://MenuPrincipal.tscn")

# Callbacks dos botões (caso existam no .tscn)
func _on_BotaoSalvar_pressed(): _salvar()
func _on_BotaoCarregar_pressed(): _carregar()
func _on_BotaoTestar_pressed(): _testar()
func _on_BotaoVoltar_pressed(): _voltar_ao_menu()

# =====================================================================
# INTERFACE DO USUÁRIO DINÂMICA
# =====================================================================
func _criar_interface_usuario():
	# 1. Menu superior (Toolbar)
	var toolbar = Panel.new()
	toolbar.name = "Toolbar"
	toolbar.rect_min_size = Vector2(0, 40)
	toolbar.rect_size = Vector2(rect_size.x, 40)
	toolbar.anchor_right = 1.0
	
	# Estilo escuro moderno
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18)
	style.border_width_bottom = 2
	style.border_color = Color(0.25, 0.25, 0.35)
	toolbar.add_stylebox_override("panel", style)
	add_child(toolbar)
	
	# HBox para alinhar botões
	var hbox = HBoxContainer.new()
	hbox.rect_position = Vector2(10, 5)
	hbox.rect_size = Vector2(rect_size.x - 20, 30)
	hbox.anchor_right = 1.0
	hbox.set("custom_constants/separation", 12)
	toolbar.add_child(hbox)
	
	# Título rápido no canto esquerdo
	var lbl_titulo = Label.new()
	lbl_titulo.text = "CORRE CONDE — EDITOR"
	lbl_titulo.align = Label.ALIGN_CENTER
	lbl_titulo.valign = Label.VALIGN_CENTER
	lbl_titulo.rect_min_size = Vector2(180, 30)
	lbl_titulo.add_color_override("font_color", Color(0.95, 0.88, 0.55))
	hbox.add_child(lbl_titulo)
	
	# Criar botões
	var btn_salvar = Button.new()
	btn_salvar.text = "💾 SALVAR FASE (Ctrl+S)"
	btn_salvar.rect_min_size = Vector2(160, 30)
	btn_salvar.connect("pressed", self, "_salvar")
	hbox.add_child(btn_salvar)
	
	var btn_carregar = Button.new()
	btn_carregar.text = "📂 CARREGAR (Ctrl+L)"
	btn_carregar.rect_min_size = Vector2(140, 30)
	btn_carregar.connect("pressed", self, "_carregar")
	hbox.add_child(btn_carregar)
	
	var btn_testar = Button.new()
	btn_testar.text = "▶️ TESTAR JOGO (Ctrl+T)"
	btn_testar.rect_min_size = Vector2(160, 30)
	var style_testar = StyleBoxFlat.new()
	style_testar.bg_color = Color(0.15, 0.5, 0.25)
	style_testar.border_width_bottom = 2
	style_testar.border_color = Color(0.1, 0.35, 0.15)
	btn_testar.add_stylebox_override("normal", style_testar)
	btn_testar.connect("pressed", self, "_testar")
	hbox.add_child(btn_testar)
	
	var btn_limpar = Button.new()
	btn_limpar.text = "🧹 LIMPAR TUDO"
	btn_limpar.rect_min_size = Vector2(110, 30)
	btn_limpar.connect("pressed", self, "_confirmar_limpeza")
	hbox.add_child(btn_limpar)
	
	var btn_ajuda = Button.new()
	btn_ajuda.text = "❓ AJUDA / TECLAS"
	btn_ajuda.rect_min_size = Vector2(130, 30)
	var style_ajuda = StyleBoxFlat.new()
	style_ajuda.bg_color = Color(0.4, 0.2, 0.5)
	style_ajuda.border_width_bottom = 2
	style_ajuda.border_color = Color(0.25, 0.1, 0.35)
	btn_ajuda.add_stylebox_override("normal", style_ajuda)
	btn_ajuda.connect("pressed", self, "_mostrar_ajuda")
	hbox.add_child(btn_ajuda)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	var btn_voltar = Button.new()
	btn_voltar.text = "🚪 SAIR (Esc)"
	btn_voltar.rect_min_size = Vector2(100, 30)
	btn_voltar.connect("pressed", self, "_voltar_ao_menu")
	hbox.add_child(btn_voltar)

func _confirmar_limpeza():
	var dialog = ConfirmationDialog.new()
	dialog.window_title = "Limpar Mapa"
	dialog.dialog_text = "Deseja realmente limpar todo o mapa e recomecar do zero?"
	dialog.rect_min_size = Vector2(400, 120)
	dialog.connect("confirmed", self, "_limpar_mapa")
	dialog.connect("popup_hide", dialog, "queue_free")
	add_child(dialog)
	dialog.popup_centered()

func _limpar_mapa():
	_salvar_undo()
	_criar_mapa_padrao()

func _mostrar_ajuda():
	var dialog = AcceptDialog.new()
	dialog.window_title = "Guia de Controles e Legendas"
	dialog.rect_min_size = Vector2(600, 480)
	
	var scroll = ScrollContainer.new()
	scroll.rect_min_size = Vector2(580, 420)
	
	var label = Label.new()
	label.autowrap = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = """=== CONTROLES DO MOUSE ===
• Clique Esquerdo: Desenha blocos ou posiciona o objeto selecionado.
• Clique Direito: Apaga blocos ou objetos do grid.
• Botão do Meio (MMB) + Arrastar: Move a câmera pelo mapa (Pan).
• Roda do Mouse: Zoom in / Zoom out.

=== COMO USAR A PALETA ===
• Clique em uma textura na barra lateral e desenhe no grid.
• Clique em um objeto da barra lateral para entrar no modo de colocação.
  - P: Posiciona o Conde (Jogador). OBRIGATÓRIO!
  - S: Posiciona a Saída (Portal Dourado). OBRIGATÓRIO!
  - Lobo: Inimigo básico terrestre.
  - Crucifixo: Obstáculo estático de dano de luz.
  - Paladino: Chefão que atira estacas.
  - Caixão: Plataforma que treme e desmorona após ser pisada.
  - Pó Mágico: Semente que gera a Árvore Protetora (cura e cria sombra contra o sol).
  - P.Anel: Coletável. O Conde precisa de 3 pedaços antes de poder derrotar o Paladino.
  - Portal: Teletransporte de fim de fase alternativo.
  - Lâmpada / Caixa: Decoração física e obstáculo empurrável.

=== ATALHOS DE TECLADO ===
• Ctrl + S: Salvar fase na pasta customizada com nome.
• Ctrl + L: Carregar fase criada anteriormente.
• Ctrl + T: Testar a fase imediatamente jogando!
• Ctrl + Z: Desfazer alteração.
• Ctrl + Y: Refazer alteração.
• Ctrl + Setas: Redimensionar largura/altura do grid.
• G: Ativa preenchimento (Flood Fill).
• F: Cicla entre 5 presets de fundo (Noite, Castelo, Floresta, Cemitério, Lua Cheia).
• Esc: Sai do editor e retorna ao menu de fases criadas.

=== COMO RETORNAR AO EDITOR ===
• Durante os testes da fase, você pode clicar no botão vermelho no canto superior esquerdo ou apertar 'Backspace' a qualquer momento para voltar ao editor e continuar a criar!"""
	
	scroll.add_child(label)
	dialog.add_child(scroll)
	dialog.connect("popup_hide", dialog, "queue_free")
	add_child(dialog)
	dialog.popup_centered()
