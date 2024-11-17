extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var syncPos = Vector2(0, 0)
var syncRot = 0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var bullet :PackedScene

# Health variables
var health = 100.0
const MAX_HEALTH = 100.0
const MIN_HEALTH = 0.0

enum CharacterState { ATTACK, RUN, DEAD, IDLE }
var state_to_string = {
  CharacterState.ATTACK: "attack",
  CharacterState.RUN: "run",
  CharacterState.DEAD: "dead",
  CharacterState.IDLE: "idle",
}
var current_state = CharacterState.IDLE

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	velocity = Vector2.ZERO
	syncPos = global_position
	anim.play(state_to_string[CharacterState.IDLE])

func _physics_process(delta: float) -> void:
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		if current_state == CharacterState.ATTACK and anim.is_playing():
			return

		var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

		# Handle attack action
		if Input.is_action_just_pressed("E"):  # Replace "spaceBar" with your action
			current_state = CharacterState.ATTACK
			print("attack")
			anim.play(state_to_string[CharacterState.ATTACK])
			return  # Skip further processing during attack

		# Handle other actions (e.g., projectile action)
		if Input.is_action_just_pressed("spaceBar"):
			fire.rpc()
		$GunRotation.look_at(get_viewport().get_mouse_position())
		syncRot = rotation_degrees
		# Handle movement and idle states
		if input_vector == Vector2.ZERO:
			if current_state != CharacterState.IDLE:  # Prevent re-playing idle
				current_state = CharacterState.IDLE
				anim.play(state_to_string[CharacterState.IDLE])
		else:
			if current_state != CharacterState.RUN:  # Prevent re-playing run
				current_state = CharacterState.RUN
				anim.play(state_to_string[CharacterState.RUN])
			if input_vector.x != 0:  # Moving left or right
				anim.flip_h = input_vector.x < 0  # True for left, False for right

		# Update syncPos and apply movement
		syncPos = global_position
		velocity = input_vector * SPEED
		move_and_slide()
		 # Health check
		if health <= MIN_HEALTH:
			print("DEAD")
			current_state = CharacterState.DEAD
			anim.play(state_to_string[CharacterState.DEAD])
			# You can add additional death logic here (e.g., stop movement or respawn)
	else:
		# Sync position if not the authority
		global_position = global_position.lerp(syncPos, 0.5)

# Handle animation transitions
#func _on_animation_finished(anim_name: String) -> void:
	#print(anim_name)
	#if anim_name == state_to_string[CharacterState.ATTACK]:
		#current_state = CharacterState.IDLE
		#anim.play(state_to_string[CharacterState.IDLE])
		#rotation_degrees = lerpf(rotation_degrees, syncRot, .5)


func _on_animated_sprite_2d_animation_finished() -> void:
	print("finished anim")
	print("current state " + state_to_string[CharacterState.ATTACK])
	if current_state == CharacterState.ATTACK:
		current_state = CharacterState.IDLE
		anim.play(state_to_string[CharacterState.IDLE])

@rpc("any_peer","call_local")
func fire():
	var b = bullet.instantiate()
	b.global_position = $GunRotation/BulletSpawn.global_position
	b.rotation_degrees = $GunRotation.rotation_degrees
	get_tree().root.add_child(b)
