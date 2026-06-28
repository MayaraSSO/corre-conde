extends CanvasLayer

var teclas_fechamento = []
var pronto_para_fechar = false

onready var label_titulo = $Panel/VBoxContainer/Titulo
onready var label_mensagem = $Panel/VBoxContainer/Mensagem
onready var label_instrucao = $Panel/VBoxContainer/Instrucao

func _ready():
	# Define o pause_mode do CanvasLayer programaticamente para garantir que ele processe durante o Pause
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	# Pausa o jogo
	get_tree().paused = true
	
	# Atraso para evitar fechar acidentalmente se o jogador estiver apertando algo no mesmo frame
	yield(get_tree().create_timer(0.5), "timeout")
	pronto_para_fechar = true

func inicializar(titulo: String, mensagem: String, botoes_fechamento = []):
	label_titulo.text = titulo
	label_mensagem.bbcode_text = mensagem
	teclas_fechamento = botoes_fechamento
	
	if teclas_fechamento.size() > 0:
		label_instrucao.text = "Pressione as teclas de movimento para começar!"
	else:
		label_instrucao.text = "Pressione qualquer tecla para continuar..."

func _input(event):
	if not pronto_para_fechar:
		return
		
	# Só processa eventos de pressionamento de tecla (Key Events)
	if event is InputEventKey and event.pressed and not event.echo:
		if teclas_fechamento.size() > 0:
			# Checa se o evento corresponde a alguma das ações especificadas
			for acao in teclas_fechamento:
				if event.is_action(acao):
					_fechar()
					return
		else:
			# Qualquer tecla fecha o tutorial
			_fechar()

func _fechar():
	# Despausa o jogo e remove a caixa de diálogo
	get_tree().paused = false
	queue_free()
