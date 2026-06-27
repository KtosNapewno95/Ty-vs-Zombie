extends CanvasLayer

var can_restart: bool = false

@onready var main_text: Label = $Label
@onready var sub_text: Label = $Label_2 

func _ready() -> void:
	# NAPRAWA: Pozwala temu węzłowi działać i odbierać klawisze, gdy gra jest zapauzowana
	process_mode = PROCESS_MODE_WHEN_PAUSED
	
	hide()
	if Global.has_signal("player_dead"):
		Global.player_dead.connect(_on_player_dead)

func _on_player_dead() -> void:
	show()
	can_restart = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# ZATRZYMANIE GRY: zamraża fizykę i procesy w całym projekcie
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if can_restart and event.is_action_pressed("ui_accept"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		can_restart = false
		
		# ODZATRZYMANIE GRY: przywraca czas przed przeładowaniem sceny
		get_tree().paused = false
		
		get_tree().call_deferred("reload_current_scene")
