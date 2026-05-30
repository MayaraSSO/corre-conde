extends KinematicBody

var velocidade = Vector3.ZERO
var forca_pulo = 15.0
var gravidade = 35.0
var velocidade_movimento = 8.0

func _physics_process(delta):
	
	# 1. Aplicando a Gravidade
	if not is_on_floor():
		velocidade.y -= gravidade * delta
		
	# 2. Movimentação Horizontal
	var direcao_x = 0
	
	if Input.is_action_pressed("ui_right"):
		direcao_x += 1
	if Input.is_action_pressed("ui_left"):
		direcao_x -= 1
		
	velocidade.x = direcao_x * velocidade_movimento
	
	# 3. O Salto
	if Input.is_action_pressed("ui_up") and is_on_floor():
		velocidade.y = forca_pulo
		
	# 4. Trava de segurança do eixo Z
	velocidade.z = 0
	
	# 5. Executa a movimentação e colisão
	velocidade = move_and_slide(velocidade, Vector3.UP)
