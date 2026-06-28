extends Spatial

# Parâmetros calibrados para o motor físico do Godot
var altura_atual = 0.5
var altura_maxima = 14.0
var velocidade_crescimento = 2.8 # Metros por segundo

var ativa = false
var conde_ref = null

onready var tronco = $Tronco
onready var copa = $Copa
onready var sombra_visual = $SombraVisual
onready var colisor_sombra = $AreaSombra/CollisionShape

func _ready():
	# Inicializa pequena
	tronco.scale = Vector3(0.4, altura_atual, 0.4)
	copa.scale = Vector3(2.5, 2.5, 2.5)
	copa.translation.y = altura_atual
	
	sombra_visual.scale = Vector3(0.01, 1.0, 1.0)
	colisor_sombra.disabled = true

func inicializar(pos_x):
	translation.x = pos_x
	translation.y = 0.0 # Alinhado com o chão físico das plataformas
	translation.z = 0.0
	altura_atual = 0.5
	ativa = true
	visible = true
	copa.visible = true
	colisor_sombra.disabled = false
	print("[ArvoreProtetora] Plantada e ativa em X: ", pos_x)

func _process(delta):
	if not ativa:
		return
		
	if altura_atual < altura_maxima:
		altura_atual += velocidade_crescimento * delta
		if altura_atual > altura_maxima:
			altura_atual = altura_maxima
			
		# Atualiza o tronco (Cilindro com altura 2.0 por padrão)
		# Para crescer verticalmente a partir da base, escalamos o Y e movemos a origem Y para metade do tamanho.
		tronco.scale.y = altura_atual
		tronco.translation.y = altura_atual # Cilindro padrão de raio 1, altura 2.0 -> a base fica em Y=0 se mover para Y=altura_atual.
		
		# Atualiza a copa (no topo do tronco)
		copa.translation.y = altura_atual * 2.0
		
		# Projeção de Sombra: comprimento = altura * 2.2
		var comp_sombra = altura_atual * 2.2
		
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

func _on_AreaSombra_body_exited(body):
	if body.name == "Conde" and conde_ref == body:
		body.imune_ao_sol = false
		conde_ref = null
		print("[Sombra] Conde saiu da área segura.")
