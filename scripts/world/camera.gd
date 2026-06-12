extends Camera2D

const PAN_SPEED: float = 600.0
const ZOOM_STEP: float = 0.1
const ZOOM_MIN: float = 0.25
const ZOOM_MAX: float = 3.0
# Dialogue panel is 360px tall; at default zoom 1.3 that's ~277 world units.
# Shift the follow target down by half that so the player sits in the center
# of the usable area above the dialogue box.
const DIALOGUE_OFFSET_Y: float = 138.5
const FOLLOW_SPEED: float = 6.0

var _follow_player: bool = true

func _ready() -> void:
	# Disable built-in limits — grid is large enough that empty space
	# beyond the edges is acceptable for now.
	limit_left   = -100000
	limit_right  =  100000
	limit_top    = -100000
	limit_bottom =  100000
	if GameManager.player != null and is_instance_valid(GameManager.player):
		position = GameManager.player.position + Vector2(0, DIALOGUE_OFFSET_Y)
	else:
		position = Vector2(0, 1280)
	zoom = Vector2(1.3, 1.3)
	make_current()

func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): direction.y -= 1
	if Input.is_key_pressed(KEY_S): direction.y += 1
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_D): direction.x += 1
	if direction != Vector2.ZERO:
		_follow_player = false   # manual pan disables follow
		# Scale pan speed with zoom so panning feels consistent when zoomed in/out
		position += direction.normalized() * PAN_SPEED * delta / zoom.x
	elif _follow_player and GameManager.player != null and is_instance_valid(GameManager.player):
		var target: Vector2 = GameManager.player.position + Vector2(0, DIALOGUE_OFFSET_Y)
		position = position.lerp(target, FOLLOW_SPEED * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_follow_player = !_follow_player
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom + Vector2(ZOOM_STEP, ZOOM_STEP)).clamp(
				Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom - Vector2(ZOOM_STEP, ZOOM_STEP)).clamp(
				Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))
