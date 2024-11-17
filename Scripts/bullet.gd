extends CharacterBody2D


const SPEED = 50.0
var damage = 20  # Amount of damage to deal on hit

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction : Vector2

func _ready():
	direction = Vector2(1,0).rotated(rotation)

func _physics_process(delta):
	# Add the gravity.
	velocity = SPEED * direction
	if not is_on_floor():
		velocity.y += gravity * 1 * delta
	move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	print(body)
	print("HIT")
	queue_free()
