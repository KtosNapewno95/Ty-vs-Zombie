extends Node3D

# Przeciągnij tutaj swój węzeł WorldEnvironment z drzewa sceny
@onready var world_environment: WorldEnvironment = $WorldEnvironment

func _unhandled_input(event: InputEvent) -> void:
	# Sprawdzamy, czy wciśnięto klawisz 'S' przy jednoczesnym trzymaniu klawisza 'Alt'
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_S and event.alt_pressed:
			toggle_volumetric_fog()

func toggle_volumetric_fog() -> void:
	if world_environment and world_environment.environment:
		var env: Environment = world_environment.environment
		
		# Zmieniamy stan mgły na przeciwny (włączona -> wyłączona / wyłączona -> włączona)
		env.volumetric_fog_enabled = not env.volumetric_fog_enabled
		
		# Opcjonalny komunikat w konsoli edytora, żebyś widział stan
		print("Wolumetryczna mgła: ", env.volumetric_fog_enabled)
