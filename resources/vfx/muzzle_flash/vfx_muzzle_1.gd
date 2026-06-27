extends Node3D

@onready var mesh: MeshInstance3D = $MuzzleFlashFPS
@onready var omni_light: OmniLight3D = $OmniLight3D
@onready var smoke: GPUParticles3D = $Smoke
@onready var sparks: GPUParticles3D = $Sparks

@export var flash_duration: float = 0.05
@export var base_light_energy: float = 5.0  # Bazowa moc błysku (podkręć, jeśli chcesz jaśniej)

func _ready() -> void:
	activate()

func activate() -> void:
	show_effects()
	
	# Licznik dla ukrycia samej siatki (flash)
	var muzzle_timer = get_tree().create_timer(flash_duration)
	muzzle_timer.timeout.connect(hide_effects)

func show_effects() -> void:
	# 1. Losowość: Obracamy błysk wokół osi Z i delikatnie zmieniamy skalę, 
	# dzięki czemu każdy strzał wygląda unikalnie
	mesh.rotation.z = randf_range(0, 360)
	var random_scale = randf_range(0.8, 1.3)
	mesh.scale = Vector3(random_scale, random_scale, random_scale)
	
	mesh.visible = true
	omni_light.visible = true
	
	# 2. Dynamiczne światło i mgła wolumetryczna
	omni_light.light_energy = base_light_energy
	# Sprawia, że wystrzał na ułamek sekundy pięknie rozświetli mgłę wokół lufy
	omni_light.light_volumetric_fog_energy = base_light_energy * 2.0 
	
	# 3. Płynne wygaszanie światła za pomocą Tweena
	var light_tween = create_tween()
	light_tween.tween_property(omni_light, "light_energy", 0.0, flash_duration * 2.0)
	light_tween.parallel().tween_property(omni_light, "light_volumetric_fog_energy", 0.0, flash_duration * 2.0)
	
	# Restart cząsteczek dymu i iskier
	smoke.restart()
	sparks.restart()

func hide_effects() -> void:
	# Ukrywamy samą siatkę błysku, ale światło wciąż płynnie wygasa przez Tweena
	mesh.visible = false
	
	# Czekamy, aż dym i iskry znikną naturalnie przed usunięciem węzła
	await get_tree().create_timer(2.0).timeout
	queue_free()
