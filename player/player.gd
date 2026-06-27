extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 6.0
var speed: float = 0.0
const GRAVITY: float = -20

# === NOWE: Przechowywanie wagi aktualnej broni ===
var current_weapon_speed_modifier: float = 1.0
# ================================================

@export var sensitivity:float = 0.01
var inertia_air:float = 7.5
var inertia_ground: float = 10.0

#BOB
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

var is_aiming: bool = false

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_holder: Node3D = $CameraPivot/CameraHolder
@onready var camera: Camera3D = %MainCamera
@onready var audio_manager: Node3D = $AudioManager
@onready var weapons_manager: Node3D = $WeaponsManager

@export var weapon:Node3D
var walk_anim:float = 0.0
var sprint_anim:float = 0.0

# Animation blend speeds
const ANIM_BLEND_SPEED: float = 20.0

# Audio tracking
var was_on_floor: bool = false
var footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL_WALK: float = 0.5
const FOOTSTEP_INTERVAL_SPRINT: float = 0.3

const MAX_HEALTH:float = 100.0
var current_health:float = 100.0
var is_alive: bool = true
const HIT_STAGGER: float = 40.0

func _ready() -> void:
	Global.player = self
	Global.aim_mode_changed.connect(_on_aim_mode_changed)
	
	# === NOWE: Łączenie z sygnałem zmiany wagi broni z Menedżera Broni ===
	if Global.has_signal("weapon_speed_modifier_changed"):
		Global.weapon_speed_modifier_changed.connect(_on_weapon_speed_changed)

# === NOWA FUNKCJA: Odbieranie sygnału o wadze broni ===
func _on_weapon_speed_changed(modifier: float) -> void:
	current_weapon_speed_modifier = modifier
# ======================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * sensitivity)
		camera_holder.rotate_x(-event.relative.y * sensitivity)
		camera_holder.rotation.x = clamp(camera_holder.rotation.x, deg_to_rad(-60),deg_to_rad(60))

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Detect landing from air
	if is_on_floor() and not was_on_floor:
		# Player just landed
		if audio_manager:
			audio_manager.play_footstep(true)  # Play jump/land sound
	
	# Update floor state tracker
	was_on_floor = is_on_floor()

	# Handle jump (ZMIENIONO: Waga broni wpływa również na wysokość skoku)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity * current_weapon_speed_modifier

	# Handle sprint
	if Input.is_action_pressed("sprint"):
		handle_sprint()
	else:
		handle_walk()

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# POPRAWKA BŁĘDU: Naprawiłem literówkę w Twoim oryginalnym kodzie (było direction.x zamiast direction.z dla osi Z)
			velocity.x = lerp(velocity.x, direction.x * speed, delta * inertia_ground)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * inertia_ground)
	else:
		# POPRAWKA BŁĘDU: Naprawiłem literówkę w Twoim oryginalnym kodzie (było direction.x zamiast direction.z dla osi Z)
		velocity.x = lerp(velocity.x, direction.x * speed, delta * inertia_air)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * inertia_air)

	# head bob
	t_bob += velocity.length() * float(is_on_floor()) * delta
	camera_holder.transform.origin = _headbob(t_bob)
	
	# Handle footstep sounds
	_handle_footsteps(delta)
	
	# Emit velocity for crosshair
	Global.player_velocity_changed.emit(velocity)

	move_and_slide()

func _handle_footsteps(delta: float) -> void:
	if is_on_floor() and velocity.length() > 0.1:
		footstep_timer -= delta
		
		if footstep_timer <= 0.0:
			var interval = FOOTSTEP_INTERVAL_SPRINT if Input.is_action_pressed("sprint") else FOOTSTEP_INTERVAL_WALK
			
			# Opcjonalnie: Ciężka broń wydłuża odstęp między krokami, dopasowując dźwięk do wolniejszego chodu
			interval = interval / current_weapon_speed_modifier
			footstep_timer = interval
			
			if audio_manager:
				audio_manager.play_footstep(false)
	else:
		footstep_timer = 0.0

func handle_walk() -> void:
	# ZMIENIONO: Prędkość chodu przemnożona przez wagę broni
	speed = walk_speed * current_weapon_speed_modifier
	Global.player_sprinting_changed.emit(false)

func handle_sprint() -> void:
	if is_aiming:
		handle_walk()
		return
	
	# ZMIENIONO: Prędkość sprintu przemnożona przez wagę broni
	speed = sprint_speed * current_weapon_speed_modifier
	Global.player_sprinting_changed.emit(true)

func _on_aim_mode_changed(aim_mode: bool) -> void:
	is_aiming = aim_mode
	if aim_mode and Input.is_action_pressed("sprint"):
		handle_walk()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin (time * BOB_FREQ) * BOB_AMP
	pos.x = cos (time * BOB_FREQ/2) * BOB_AMP
	return pos

func get_damage(damage:float,direction:Vector3, is_enemy_damage:bool = false) -> void:
	current_health -= damage
	if current_health < 0.0:
		current_health = 0.0
		is_alive = false
		Global.player_dead.emit()
	else:
		velocity +=  direction * HIT_STAGGER
	Global.player_health_changed.emit(-damage,current_health,MAX_HEALTH, is_enemy_damage)
