tool
class_name JumpBackAndForthBehaviorController, \
"res://addons/surfacer/assets/images/editor_icons/jump_back_and_forth_behavior_controller.png"
extends BehaviorController


# FIXME: -------------------------


const CONTROLLER_NAME := "jump_back_and_forth"
const IS_ADDED_MANUALLY := true


func _init().(CONTROLLER_NAME, IS_ADDED_MANUALLY) -> void:
    pass


#func _on_player_ready() -> void:
#    ._on_player_ready()


#func _on_attached_to_first_surface() -> void:
#    ._on_attached_to_first_surface()


#func _on_active() -> void:
#    ._on_active()


#func _on_ready_to_move() -> void:
#    ._on_ready_to_move()


#func _on_inactive() -> void:
#    ._on_inactive()


#func _on_navigation_ended(did_navigation_finish: bool) -> void:
#    ._on_navigation_ended(did_navigation_finish)


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


#func _update_parameters() -> void:
#    ._update_parameters()
#
#    if _configuration_warning != "":
#        return
#
#    # FIXME: ----------------------------
#
#    _set_configuration_warning("")


func _get_default_next_behavior_controller() -> BehaviorController:
    return player.active_at_start_controller
