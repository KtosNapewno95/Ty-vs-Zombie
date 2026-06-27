extends Node3D

@onready var omni_light: OmniLight3D = $OmniLight3D
@onready var fire: GPUParticles3D = $Fire
@onready var sparks: GPUParticles3D = $Sparks
@onready var smoke: GPUParticles3D = $Smoke
@onready var debri: GPUParticles3D = $Debri
@onready var debri_smoke: GPUParticles3D = $DebriSmoke
@onready var explosion_sfx: AudioStreamPlayer3D = $ExplosionSFX

@export var fire_amount: int = 150
@export var sparks_amount: int = 800
@export var smoke_amount: int = 200
@export var debri_amount: int = 50
@export var debri_smoke_amount: int = 350 # Zwiększamy nieco, by starczyło na ślady za odłamkami

func activate() -> void:
	# Przypisanie ilości cząsteczek
	fire.amount = fire_amount
	sparks.amount = sparks_amount
	smoke.amount = smoke_amount
	debri.amount = debri_amount
	
	# Ważne: Pod-emiter (debri_smoke) musi mieć ustawioną ilość,
	# ale NIE odpalamy go ręcznie za pomocą .restart(), bo to główne odłamki będą nim sterować!
	if debri_smoke:
		debri_smoke.amount = debri_smoke_amount

	# Odpalenie efektów
	omni_light.visible = true
	fire.restart()
	sparks.restart()
	smoke.restart()
	debri.restart() # To uruchomi odłamki i automatycznie ich płonące ogony!
	explosion_sfx.play()
	
	await get_tree().create_timer(0.1).timeout
	omni_light.visible = false
