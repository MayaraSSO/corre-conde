extends StaticBody

var pisado = false
export var limite_tremor = 0.3
export var dano_caixao = 15.0
var tempo_tremor = 0.0
var conde_dentro = null
var pos_original = Vector3.ZERO

onready var mesh_base = $MeshBase
onready var colisor_fisico = $CollisionShape
onready var colisor_area = $AreaDetecao/CollisionShape

func _ready():
	# Conecta o sinal de entrada na Area de detecção
	$AreaDetecao.connect("body_entered", self, "_on_body_entered")
	pos_original = mesh_base.translation
	set_process(false)

func _on_body_entered(body):
	if body.name == "Conde" and not pisado:
		pisado = true
		conde_dentro = body
		set_process(true)
		print("[Caixao] O Conde pisou no caixão! Começando a tremer...")

func _process(delta):
	tempo_tremor += delta
	if tempo_tremor < limite_tremor:
		# Tremor visual progressivo (intensidade aumenta com o tempo)
		var intensidade = lerp(0.1, 0.35, tempo_tremor / limite_tremor)
		var offset_x = (randf() - 0.5) * intensidade
		var offset_z = (randf() - 0.5) * intensidade
		mesh_base.translation = Vector3(pos_original.x + offset_x, pos_original.y, pos_original.z + offset_z)
	else:
		# Fim do tremor: Quebra!
		set_process(false)
		_quebrar()

func _quebrar():
	print("[Caixao] Quebrou!")
	# Desabilita colisores de forma segura usando set_deferred
	colisor_fisico.set_deferred("disabled", true)
	colisor_area.set_deferred("disabled", true)
	
	# Oculta todo o visual do caixão
	mesh_base.visible = false
	
	# Aplica dano ao Conde
	if conde_dentro != null and is_instance_valid(conde_dentro):
		# Aplica dano parametrizado
		conde_dentro.ultimo_dano_recebido = "caixao"
		conde_dentro.energia_vital = max(0.0, conde_dentro.energia_vital - dano_caixao)
		var barra = conde_dentro.get_node_or_null("HUD/BarraVida")
		if barra != null:
			barra.value = conde_dentro.energia_vital
		print("[Caixao] DANO: Conde perdeu ", dano_caixao, "% de vida ao quebrar o caixão!")
		
	# Espera 1 segundo invisível e remove da cena
	yield(get_tree().create_timer(1.0), "timeout")
	queue_free()


