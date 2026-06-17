extends KinematicBody

var velocidade = Vector3.ZERO
var forca_pulo = 15.0
var gravidade = 35.0
var velocidade_movimento = 8.0


# --- NOVAS VARIÁVEIS DE VIDA E LUZ ---
var energia_vital = 100.0
var tomando_dano_de_luz = false
var dano_da_luz_por_segundo = 15.0


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
	
	# 6. Sistema de Dano da Luz (Com trava de valor mínimo)
	if tomando_dano_de_luz == true:
		# Subtrai o dano normalmente
		energia_vital -= dano_da_luz_por_segundo * delta
		
		# Atualiza o visual da barra na tela
		$HUD/BarraVida.value = energia_vital
		
		# Guarda de segurança: se a energia cair abaixo de zero, fixamos em zero
		if energia_vital <= 0:
			energia_vital = 0
			print("GAME OVER: O Conde virou cinzas sob o sol!")
			var _erro = get_tree().reload_current_scene()
		# No futuro, aqui chamaremos a função de reiniciar a fase
		else:
			# O 'stepify' limpa os números quebrados do float, mostrando só 1 casa decimal
			print("CUIDADO! Energia: ", stepify(energia_vital, 0.1))

func _on_ZonaLuz_body_entered(body):
	if body.name == "Conde":
		tomando_dano_de_luz = true

func _on_ZonaLuz_body_exited(body):
	if body.name == "Conde":
		tomando_dano_de_luz = false
