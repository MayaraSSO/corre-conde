extends Area

export var velocidade_perseguicao = 2.5
var perseguindo = false
var tempo_espera = 8.0

# Variável para rastrear se o Conde está dentro da luz
var conde_sendo_queimado = null

func _process(delta):
	# 1. Movimento da Parede de Luz
	if perseguindo:
		if tempo_espera > 0:
			tempo_espera -= delta
		else:
			translation.x += velocidade_perseguicao * delta
			
	# 2. Sistema de Dano Contínuo
	if conde_sendo_queimado != null:
		# Tira 20 pontos de vida POR SEGUNDO
		conde_sendo_queimado.energia_vital -= 20.0 * delta 
		conde_sendo_queimado.get_node("HUD/BarraVida").value = conde_sendo_queimado.energia_vital
func _on_ZonaLuz_body_entered(body):
	if body.name == "Conde":
		print("ENTROU NA LUZ: Começou a tomar dano!")
		conde_sendo_queimado = body

func _on_ZonaLuz_body_exited(body):
	if body.name == "Conde":
		print("SAIU DA LUZ: Dano parou!")
		conde_sendo_queimado = null
