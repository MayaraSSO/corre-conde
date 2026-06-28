extends Area

var ativado = false
var tempo = 0.0
var conde = null

func _ready():
	# Começa invisível/minúsculo e expande
	scale = Vector3.ZERO
	var _err = connect("body_entered", self, "_on_body_entered")
	print("[Portal] Portal inicializado e pronto para receber o Conde.")

func _process(delta):
	# Animação de crescimento suave ao surgir
	if scale.x < 1.5 and not ativado:
		scale = scale.linear_interpolate(Vector3(1.5, 1.5, 1.5), 5.0 * delta)
		
	# Rotaciona o sprite no plano 2D para dar o efeito de espiral giratória
	$MeshInstance.rotation_degrees.z += 90.0 * delta
	
	# Redundância: Checa se o Conde já está dentro da área caso o sinal body_entered falhe
	if not ativado:
		for body in get_overlapping_bodies():
			if body.name == "Conde":
				_on_body_entered(body)
				break
	
	if ativado and conde != null:
		# Efeito de sucção: atração ao centro do portal, encolhimento e rotação de redemoinho
		if is_instance_valid(conde):
			conde.translation = conde.translation.linear_interpolate(translation, 6.0 * delta)
			conde.scale = conde.scale.linear_interpolate(Vector3.ZERO, 6.0 * delta)
			
			var sprite = conde.get_node_or_null("SpriteConde")
			if sprite != null:
				sprite.rotation_degrees.z += 720.0 * delta # Gira o Conde rapidamente
				
		scale = scale.linear_interpolate(Vector3.ZERO, 6.0 * delta)
		
		tempo += delta
		if tempo >= 1.2:
			# Garante que o Conde não comece travado e despausa
			get_tree().paused = false
			DadosJogo.fase_atual = 2
			var _r = get_tree().change_scene("res://Fase2.tscn")

func _on_body_entered(body):
	if body.name == "Conde" and not ativado:
		ativado = true
		conde = body
		body.input_travado = true # Trava os movimentos e velocidade do Conde
		body.velocidade = Vector3.ZERO
		print("[Portal] Conde entrou! Iniciando teletransporte para a Fase 2...")
