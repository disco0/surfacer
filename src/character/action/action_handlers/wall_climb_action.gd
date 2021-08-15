class_name WallClimbAction
extends CharacterActionHandler


const NAME := "WallClimbAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 150


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if !character.processed_action(WallJumpAction.NAME) and \
            !character.processed_action(WallFallAction.NAME) and \
            !character.processed_action(WallWalkAction.NAME):
        if character.actions.pressed_up:
            character.velocity.y = character.movement_params.climb_up_speed
            return true
        elif character.actions.pressed_down:
            character.velocity.y = character.movement_params.climb_down_speed
            return true
    
    return false
