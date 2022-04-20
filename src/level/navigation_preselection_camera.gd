class_name NavigationPreselectionCamera
extends ScaffolderCamera


const _PAN_AND_ZOOM_INTERVAL := 0.05

var _interval_id := -1

var _delta_offset := Vector2.INF
var _delta_zoom := INF

var target_character: ScaffolderCharacter


func _init() -> void:
    Sc.level.touch_listener.connect(
            "single_touch_dragged", self, "_on_dragged")
    Sc.level.touch_listener.connect(
            "single_touch_released", self, "_on_released")


func _destroy() -> void:
    ._destroy()
    Sc.time.clear_interval(_interval_id)


func _validate() -> void:
    assert(Sc.camera.max_zoom_from_pointer >= 1.0)
    assert(Sc.camera.max_pan_distance_from_pointer >= 0.0)
    assert(Sc.camera.screen_size_ratio_distance_from_edge_to_start_pan_from_pointer <= \
            0.5 and \
            Sc.camera.screen_size_ratio_distance_from_edge_to_start_pan_from_pointer > \
            0.0)


func _set_is_active(value: bool) -> void:
    ._set_is_active(value)
    if value:
        assert(is_instance_valid(target_character))


func _physics_process(delta: float) -> void:
    var old_misc_offset := _misc_offset
    if is_instance_valid(target_character):
        _misc_offset = target_character.position
    else:
        _misc_offset = Vector2.ZERO
    if _misc_offset != old_misc_offset:
        _update_offset_and_zoom()


func _on_dragged(
        pointer_screen_position: Vector2,
        pointer_level_position: Vector2,
        has_corresponding_touch_down: bool) -> void:
    if !is_instance_valid(Sc.characters.get_active_player_character()) or \
            Sc.level.touch_listener.get_is_control_pressed():
        _stop_drag()
        return
    _update_pan_and_zoom_delta_from_pointer(pointer_level_position)
    _update()


func _on_released(
        pointer_screen_position: Vector2,
        pointer_level_position: Vector2,
        has_corresponding_touch_down: bool) -> void:
    _stop_drag()


func _stop_drag() -> void:
    Sc.time.clear_interval(_interval_id)
    _interval_id = -1
    
    _delta_offset = Vector2.INF
    _delta_zoom = INF
    
    if Sc.camera.snaps_camera_back_to_character:
        reset()


func _update() -> void:
    if _interval_id < 0:
        _interval_id = Sc.time.set_interval(
                funcref(self, "_update_camera_from_deltas"),
                _PAN_AND_ZOOM_INTERVAL)


func _update_camera_from_deltas() -> void:
    assert(_delta_offset != Vector2.INF)
    assert(!is_inf(_delta_zoom))
    
    # Calculate the next values.
    var next_offset := _target_offset + _delta_offset
    var next_zoom := \
            _target_zoom + _delta_zoom if \
            Sc.camera.snaps_camera_back_to_character else \
            1.0
    
    # Don't let the pan and zoom exceed their max bounds.
    next_offset.x = clamp(
            next_offset.x,
            -Sc.camera.max_pan_distance_from_pointer,
            Sc.camera.max_pan_distance_from_pointer)
    next_offset.y = clamp(
            next_offset.y,
            -Sc.camera.max_pan_distance_from_pointer,
            Sc.camera.max_pan_distance_from_pointer)
    next_zoom = clamp(
            next_zoom,
            1.0,
            Sc.camera.max_zoom_from_pointer)
    
    _update_controller_pan_and_zoom(next_offset, next_zoom)


func _update_pan_and_zoom_delta_from_pointer(
        pointer_position: Vector2) -> void:
    # Calculate the camera bounds and the region that controls pan and zoom.
    var pointer_max_control_bounds: Rect2 = self.get_visible_region()
    var camera_center := \
            pointer_max_control_bounds.position + \
            pointer_max_control_bounds.size / 2.0
    var min_control_bounds_size: Vector2 = \
            pointer_max_control_bounds.size * \
            (1 - \
            Sc.camera.screen_size_ratio_distance_from_edge_to_start_pan_from_pointer * 2)
    var min_control_bounds_position: Vector2 = \
            pointer_max_control_bounds.position + \
            pointer_max_control_bounds.size * \
            Sc.camera.screen_size_ratio_distance_from_edge_to_start_pan_from_pointer
    var pointer_min_control_bounds := Rect2(
            min_control_bounds_position,
            min_control_bounds_size)
    
    # Calculate drag control weights according to the pointer position.
    var pan_zoom_control_weight_x: float
    if pointer_position.x < camera_center.x:
        pointer_position.x = max(
                pointer_position.x,
                pointer_max_control_bounds.position.x)
        if pointer_position.x < pointer_min_control_bounds.position.x:
            # Dragging left.
            pan_zoom_control_weight_x = \
                    -1 * \
                    (pointer_min_control_bounds.position.x - \
                            pointer_position.x) / \
                    (pointer_min_control_bounds.position.x - \
                            pointer_max_control_bounds.position.x)
    else:
        pointer_position.x = min(
                pointer_position.x,
                pointer_max_control_bounds.end.x)
        if pointer_position.x > pointer_min_control_bounds.end.x:
            # Dragging right.
            pan_zoom_control_weight_x = \
                    (pointer_position.x - \
                            pointer_min_control_bounds.end.x) / \
                    (pointer_max_control_bounds.end.x - \
                            pointer_min_control_bounds.end.x)
    var pan_zoom_control_weight_y: float
    if pointer_position.y < camera_center.y:
        pointer_position.y = max(
                pointer_position.y,
                pointer_max_control_bounds.position.y)
        if pointer_position.y < pointer_min_control_bounds.position.y:
            # Dragging up.
            pan_zoom_control_weight_y = \
                    -1 * \
                    (pointer_min_control_bounds.position.y - \
                            pointer_position.y) / \
                    (pointer_min_control_bounds.position.y - \
                            pointer_max_control_bounds.position.y)
    else:
        pointer_position.y = min(
                pointer_position.y,
                pointer_max_control_bounds.end.y)
        if pointer_position.y > pointer_min_control_bounds.end.y:
            # Dragging down.
            pan_zoom_control_weight_y = \
                    (pointer_position.y - \
                            pointer_min_control_bounds.end.y) / \
                    (pointer_max_control_bounds.end.y - \
                            pointer_min_control_bounds.end.y)
    
    # Calcute the pan and zoom deltas for the current frame and drag weight.
    var per_frame_pan_ratio: float = \
            _PAN_AND_ZOOM_INTERVAL / \
            Sc.camera.duration_to_max_pan_from_pointer_at_max_control
    var per_frame_zoom_ratio: float = \
            _PAN_AND_ZOOM_INTERVAL / \
            Sc.camera.duration_to_max_zoom_from_pointer_at_max_control
    var max_pan_distance_per_frame: float = \
            Sc.camera.max_pan_distance_from_pointer * per_frame_pan_ratio
    var max_zoom_delta_per_frame: float = \
            Sc.camera.max_zoom_from_pointer * per_frame_zoom_ratio
    _delta_offset = Vector2(
            pan_zoom_control_weight_x * max_pan_distance_per_frame,
            pan_zoom_control_weight_y * max_pan_distance_per_frame)
    _delta_zoom = \
            max(abs(pan_zoom_control_weight_x),
                abs(pan_zoom_control_weight_y)) * \
            max_zoom_delta_per_frame
