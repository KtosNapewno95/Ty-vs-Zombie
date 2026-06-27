extends StaticBody3D

var destroyable_items_in_range:Array = []
var damage:float = 200.0
@onready var blast_radius: Area3D = $BlastRadius
@onready var explosion_vfx: Node3D = $ExplosionVFX


func get_damage(_damage,_direction) -> void:
	destroy()


func destroy() -> void:
	$barrel.visible = false
	$CollisionShape3D.disabled = true
	explosion_vfx.activate()
	
	# --- NOWY KOD: TWORZENIE BŁYSKU WYBUCHU ---
	var flash_light = OmniLight3D.new()
	add_child(flash_light)
	
	# Konfiguracja światła
	flash_light.light_color = Color(1.0, 0.45, 0.1) # Ciepły, pomarańczowo-czerwony kolor ognia
	flash_light.omni_range = 15.0                  # Jak daleko dociera światło (w metrach)
	flash_light.light_energy = 25.0                 # Ekstremalna jasność błysku (domyślnie to 1.0)
	
	# INTERAKCJA Z MGŁĄ: Sprawia, że błysk pięknie rozświetli mgłę wolumetryczną
	flash_light.light_volumetric_fog_energy = 15.0
	
	# Płynne wygaszanie błysku za pomocą Tweena (w 0.4 sekundy)
	var tween = create_tween()
	tween.tween_property(flash_light, "light_energy", 0.0, 0.4)
	tween.parallel().tween_property(flash_light, "light_volumetric_fog_energy", 0.0, 0.4)
	# ------------------------------------------
	
	destroyable_items_in_range = blast_radius.get_overlapping_bodies()
	if destroyable_items_in_range.size() > 0:
		for item in destroyable_items_in_range:
			if item.has_method("get_damage"):
				var direction = global_position.direction_to(item.global_position)
				
				item.get_damage(damage, direction)

	await get_tree().create_timer(2.0).timeout
	queue_free()
