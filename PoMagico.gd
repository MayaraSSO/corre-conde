extends Area

func _on_PoMagico_body_entered(body):
	if body.name == "Conde":
		print("[PoMagico] Conde coletou o pó! Brotando árvore protetora...")
		var pai = get_parent()
		if pai.has_method("brotar_arvore"):
			# Brota a árvore na posição do Conde usando call_deferred para evitar crashes de física
			pai.call_deferred("brotar_arvore", body.translation.x, body.translation.y)
		queue_free()
