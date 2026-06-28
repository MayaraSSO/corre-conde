extends Area

func _on_PoMagico_body_entered(body):
	if body.name == "Conde":
		print("[PoMagico] Conde coletou o pó! Brotando árvore protetora...")
		var pai = get_parent()
		if pai.has_method("brotar_arvore"):
			# Brota a árvore na posição do Conde
			pai.brotar_arvore(body.translation.x)
		queue_free()
