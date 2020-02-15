extends PlayerActionHandler
class_name AllDefaultAction

const NAME := "AllDefaultAction"
const TYPE := PlayerActionSurfaceType.OTHER
const PRIORITY := 10

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    # Cancel any horizontal velocity when bumping into a wall.
    if player.surface_state.is_touching_wall:
        # The move_and_slide system depends on maintained velocity always pushing the player into a
        # collision, otherwise it will eventually stop the collision. If we just zero this out,
        # is_on_wall() will give false negatives.
        player.velocity.x = player.movement_params.min_speed_to_maintain_horizontal_collision * \
                player.surface_state.toward_wall_sign
        return true
    else:
        return false
