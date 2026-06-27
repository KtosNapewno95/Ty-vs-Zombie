extends Node3D

@onready var ray_cast_origin: Node3D = $RayCastOrigin
@onready var weapon_ray_cast: RayCast3D = $RayCastOrigin/WeaponRayCast
@onready var main_camera: Camera3D = %MainCamera

# Smooth follow settings
@export var follow_speed: float = 60.0 

# Parametry odrzutu
@export var recoil_vertical_min: float = 2.0   
@export var recoil_vertical_max: float = 4.0   
@export var recoil_horizontal_range: float = 1.5 
@export var recoil_recovery_speed: float = 15.0 

var recoil_rotation: Vector3 = Vector3.ZERO

# Weapon index for switching
@export var weapons_array: Array[Node3D] = []
var current_weapon_index: int = 0
var current_weapon: Node3D

var current_aim_mode: bool = false
var is_switching: bool = false
var switch_tween: Tween

func _ready() -> void:
	current_weapon_index = 0
	_setup_current_weapon()
	
	Global.fire_input.connect(_on_fire_input)
	Global.reload_input.connect(_on_reload_input)
	Global.weapon_switch_next.connect(switch_to_next_weapon)
	Global.weapon_switch_prev.connect(switch_to_previous_weapon)
	Global.aim_mode_changed.connect(_on_aim_mode_changed)

func _setup_current_weapon() -> void:
	current_weapon = weapons_array[current_weapon_index]
	
	for weapon in weapons_array:
		weapon.initialize(main_camera, weapon_ray_cast, ray_cast_origin)
		weapon.deactivate()
	
	current_weapon.activate(current_aim_mode)
	# NOWE: Aktualizujemy prędkość gracza na start
	_update_player_speed()

func _process(_delta: float) -> void:
	recoil_rotation = recoil_rotation.lerp(Vector3.ZERO, recoil_recovery_speed * _delta)
	
	var target_transform = main_camera.global_transform
	global_position = global_position.lerp(target_transform.origin, follow_speed * _delta)
	
	var current_basis = global_transform.basis
	var target_basis = target_transform.basis
	var base_basis = current_basis.slerp(target_basis, follow_speed * _delta)
	
	var recoil_basis = Basis.from_euler(Vector3(deg_to_rad(recoil_rotation.x), deg_to_rad(recoil_rotation.y), 0))
	global_transform.basis = base_basis * recoil_basis
	
	if Input.is_action_pressed("fire") and current_weapon.burst_mode:
		if current_weapon.try_fire(false):
			apply_recoil()

func _on_fire_input() -> void:
	if current_weapon.try_fire(true):
		apply_recoil()

func apply_recoil() -> void:
	if current_weapon.has_method("is_melee_weapon") and current_weapon.is_melee_weapon:
		return
		
	var vert = randf_range(recoil_vertical_min, recoil_vertical_max)
	var horiz = randf_range(-recoil_horizontal_range, recoil_horizontal_range)
	
	if current_aim_mode:
		vert *= 0.5
		horiz *= 0.5
		
	recoil_rotation.x += vert
	recoil_rotation.y += horiz
	
	recoil_rotation.x = clamp(recoil_rotation.x, -10.0, 25.0)
	recoil_rotation.y = clamp(recoil_rotation.y, -15.0, 15.0)

# === NOWA FUNKCJA: Aktualizacja modyfikatora prędkości gracza ===
func _update_player_speed() -> void:
	var speed_modifier: float = 1.0 # 100% standardowej prędkości bazowej
	
	if current_weapon:
		# Sprawdzamy, czy w skrypcie konkretnej broni zdefiniowano zmienną 'weight_modifier'
		if "weight_modifier" in current_weapon:
			speed_modifier = current_weapon.weight_modifier
		# Jeśli nie ma zmiennej, stosujemy bezpieczny podział na bazie dotychczasowych flag:
		elif current_weapon.has_method("is_melee_weapon") and current_weapon.is_melee_weapon:
			speed_modifier = 1.15 # Z nożem/bronią białą biegasz o 15% szybciej
		elif current_weapon.get_max_ammo() > 100: # np. ciężki rkm / minigun
			speed_modifier = 0.75 # Ciężka broń spowalnia o 25%
			
	# Emitujemy sygnał do skryptu gracza
	if Global.has_signal("weapon_speed_modifier_changed"):
		Global.weapon_speed_modifier_changed.emit(speed_modifier)
# ================================================================

func _on_reload_input() -> void:
	if current_weapon.is_melee_weapon:
		return
	current_weapon.start_reload()

func _on_aim_mode_changed(aim_mode: bool) -> void:
	current_aim_mode = aim_mode

func switch_to_next_weapon() -> void:
	if current_weapon.is_reloading:
		return
	var next_index = (current_weapon_index + 1) % weapons_array.size()
	switch_weapon(next_index)

func switch_weapon(index: int) -> void:
	if index < 0 or index >= weapons_array.size():
		return
	if index == current_weapon_index and not is_switching:
		return
	
	if switch_tween:
		switch_tween.kill()
		
	recoil_rotation = Vector3.ZERO
	
	for weapon in weapons_array:
		weapon.deactivate()
	
	current_weapon_index = index
	current_weapon = weapons_array[current_weapon_index]
	is_switching = true
	
	switch_tween = create_tween()
	switch_tween.set_ease(Tween.EASE_IN_OUT)
	switch_tween.set_trans(Tween.TRANS_SINE)
	
	switch_tween.tween_property(self, "rotation_degrees:x", -30.0, 0.2)
	
	switch_tween.tween_callback(func():
		current_weapon.activate(current_aim_mode)
		Global.bullets_changed.emit()
		# NOWE: Aktualizujemy prędkość gracza dokładnie w momencie wyciągnięcia nowej broni
		_update_player_speed()
	)
	
	switch_tween.tween_property(self, "rotation_degrees:x", 10.0, 0.2)
	switch_tween.tween_property(self, "rotation_degrees:x", 0.0, 0.1)
	
	switch_tween.tween_callback(func():
		is_switching = false
	)

func switch_to_previous_weapon() -> void:
	if current_weapon.is_reloading:
		return
	var prev_index = (current_weapon_index - 1 + weapons_array.size()) % weapons_array.size()
	switch_weapon(prev_index)

func get_current_mag() -> int:
	return current_weapon.get_current_mag()

func get_current_ammo() -> int:
	return current_weapon.get_current_ammo()

func get_max_ammo() -> int:
	return current_weapon.get_max_ammo()
