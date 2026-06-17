extends Area

# Exportamos a variável para controlar a dificuldade de cada fase pelo Inspetor
export var velocidade_perseguicao = 2.5 

func _process(delta):
	# O sol avança implacavelmente para a direita no eixo X
	translation.x += velocidade_perseguicao * delta
