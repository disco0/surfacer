class_name CharacterSurfaceState
extends Reference
## -   State relating to a character's position relative to nearby surfaces.[br]
## -   This is updated each physics frame.[br]


var is_touching_floor := false
var is_touching_ceiling := false
var is_touching_left_wall := false
var is_touching_right_wall := false
var is_touching_wall := false
var is_touching_surface := false

var is_grabbing_floor := false
var is_grabbing_ceiling := false
var is_grabbing_left_wall := false
var is_grabbing_right_wall := false
var is_grabbing_wall := false
var is_grabbing_surface := false

var just_touched_floor := false
var just_touched_ceiling := false
var just_touched_wall := false
var just_touched_surface := false

var just_stopped_touching_floor := false
var just_stopped_touching_ceiling := false
var just_stopped_touching_wall := false
var just_stopped_touching_surface := false

var just_grabbed_floor := false
var just_grabbed_ceiling := false
var just_grabbed_left_wall := false
var just_grabbed_right_wall := false
var just_grabbed_surface := false

var just_stopped_grabbing_floor := false
var just_stopped_grabbing_ceiling := false
var just_stopped_grabbing_left_wall := false
var just_stopped_grabbing_right_wall := false

var is_facing_wall := false
var is_pressing_into_wall := false
var is_pressing_away_from_wall := false

var is_triggering_wall_grab := false
var is_triggering_ceiling_grab := false
var is_triggering_explicit_floor_grab := false

var is_triggering_wall_release := false
var is_triggering_ceiling_release := false

var is_triggering_fall_through := false

var is_rounding_floor_corner_to_lower_wall := false
var is_rounding_ceiling_corner_to_upper_wall := false
var is_rounding_wall_corner_to_lower_ceiling := false
var is_rounding_wall_corner_to_upper_floor := false
var is_rounding_corner := false
var is_rounding_left_corner := false

var just_changed_to_lower_wall_while_rounding_floor_corner := false
var just_changed_to_upper_wall_while_rounding_ceiling_corner := false
var just_changed_to_lower_ceiling_while_rounding_wall_corner := false
var just_changed_to_upper_floor_while_rounding_wall_corner := false
var just_changed_surface_while_rounding_corner := false

var is_descending_through_floors := false
# FIXME: -------------------------------
# - Add support for grabbing jump-through ceilings.
#   - Not via a directional key.
#   - Make this configurable for climb_adjacent_surfaces behavior.
#     - Add a property that indicates probability of climbing through instead
#       of onto.
#     - Use the same probability for fall-through-floor.
# TODO:
# - Create support for a ceiling_jump_up_action.gd?
#   - Might need a new surface state property called
#     is_triggering_jump_up_through, which would be similar to
#     is_triggering_fall_through.
# - Also create support for transitioning from standing-on-fall-through-floor
#   to clinging-to-it-from-underneath and vice versa?
#   - This might require adding support for the concept of a multi-frame
#     action?
#   - And this might require adding new Edge sub-classes for either direction?
var is_ascending_through_ceilings := false
var is_grabbing_walk_through_walls := false

var which_wall := SurfaceSide.NONE
var surface_type := SurfaceType.AIR

var center_position := Vector2.INF
var previous_center_position := Vector2.INF
var did_move_last_frame := false
var grab_position := Vector2.INF
var grab_position_tile_map_coord := Vector2.INF
var grabbed_tile_map: SurfacesTileMap
var grabbed_surface: Surface
var previous_grabbed_surface: Surface
var center_position_along_surface := PositionAlongSurface.new()
var last_position_along_surface := PositionAlongSurface.new()

var velocity := Vector2.INF

var just_changed_surface := false
var just_changed_tile_map := false
var just_changed_tile_map_coord := false
var just_changed_grab_position := false
var just_entered_air := false
var just_left_air := false

var horizontal_facing_sign := -1
var horizontal_acceleration_sign := 0
var toward_wall_sign := 0

# Dictionary<Surface, SurfaceContact>
var surfaces_to_contacts := {}
var surface_grab: SurfaceContact = null
var floor_contact: SurfaceContact
var ceiling_contact: SurfaceContact
var wall_contact: SurfaceContact

var contact_count: int setget ,_get_contact_count

var character: ScaffolderCharacter

var _collision_tile_map_coord_result := CollisionTileMapCoordResult.new()


func _init(character: ScaffolderCharacter) -> void:
    self.character = character


# Updates surface-related state according to the character's recent movement
# and the environment of the current frame.
func update() -> void:
    velocity = character.velocity
    previous_center_position = center_position
    center_position = character.position
    did_move_last_frame = previous_center_position != center_position
    
    _update_contacts()
    _update_touch_state()
    _update_action_state()


func clear_just_changed_state() -> void:
    just_touched_floor = false
    just_touched_ceiling = false
    just_touched_wall = false
    just_touched_surface = false
    
    just_stopped_touching_floor = false
    just_stopped_touching_ceiling = false
    just_stopped_touching_wall = false
    just_stopped_touching_surface = false
    
    just_grabbed_floor = false
    just_grabbed_ceiling = false
    just_grabbed_left_wall = false
    just_grabbed_right_wall = false
    just_grabbed_surface = false
    
    just_stopped_grabbing_floor = false
    just_stopped_grabbing_ceiling = false
    just_stopped_grabbing_left_wall = false
    just_stopped_grabbing_right_wall = false
    
    just_entered_air = false
    just_left_air = false
    
    just_changed_to_lower_wall_while_rounding_floor_corner = false
    just_changed_to_upper_wall_while_rounding_ceiling_corner = false
    just_changed_to_lower_ceiling_while_rounding_wall_corner = false
    just_changed_to_upper_floor_while_rounding_wall_corner = false
    just_changed_surface_while_rounding_corner = false
    
    just_changed_surface = false
    just_changed_tile_map = false
    just_changed_tile_map_coord = false
    just_changed_grab_position = false


func release_wall() -> void:
    if !is_grabbing_wall:
        return
    
    assert(is_instance_valid(wall_contact))
    surfaces_to_contacts.erase(wall_contact.surface)
    
    is_grabbing_floor = false
    is_grabbing_ceiling = false
    is_grabbing_left_wall = false
    is_grabbing_right_wall = false
    is_grabbing_wall = false
    is_grabbing_surface = false
    
    _update_touch_state()
    _update_action_state()


func release_ceiling() -> void:
    if !is_grabbing_ceiling:
        return
    
    assert(is_instance_valid(ceiling_contact))
    surfaces_to_contacts.erase(ceiling_contact.surface)
    
    is_grabbing_floor = false
    is_grabbing_ceiling = false
    is_grabbing_left_wall = false
    is_grabbing_right_wall = false
    is_grabbing_wall = false
    is_grabbing_surface = false
    
    _update_touch_state()
    _update_action_state()


func update_for_initial_surface_attachment(
        start_attachment_surface_side_or_position) -> void:
    assert(start_attachment_surface_side_or_position is Surface or \
            start_attachment_surface_side_or_position is \
                            PositionAlongSurface and \
                    start_attachment_surface_side_or_position.surface != \
                            null or \
            start_attachment_surface_side_or_position is int and \
                    start_attachment_surface_side_or_position != \
                            SurfaceSide.NONE,
            "SurfacerCharacter._start_attachment_surface_side_or_position " +
            "must be defined before adding the character to the scene tree.")
    
    var side: int = \
            start_attachment_surface_side_or_position if \
            start_attachment_surface_side_or_position is int else \
            start_attachment_surface_side_or_position.side if \
            start_attachment_surface_side_or_position is Surface else \
            start_attachment_surface_side_or_position.surface.side
    
    match side:
        SurfaceSide.FLOOR:
            assert(character.movement_params.can_grab_floors)
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            assert(character.movement_params.can_grab_walls)
        SurfaceSide.CEILING:
            assert(character.movement_params.can_grab_ceilings)
        _:
            Sc.logger.error()
    
    var start_position: Vector2 = character.position
    var normal := SurfaceSide.get_normal(side)
    
    var surface: Surface = \
            start_attachment_surface_side_or_position if \
            start_attachment_surface_side_or_position is Surface else \
            start_attachment_surface_side_or_position.surface if \
            start_attachment_surface_side_or_position is \
                    PositionAlongSurface else \
            character.surface_parser.find_closest_surface_in_direction(
                    start_position,
                    -normal,
                    _collision_tile_map_coord_result)
    
    if start_attachment_surface_side_or_position is PositionAlongSurface:
        PositionAlongSurface.copy(
                center_position_along_surface,
                start_attachment_surface_side_or_position)
    else:
        center_position_along_surface \
                .match_surface_target_and_collider(
                        surface,
                        start_position,
                        character.movement_params.collider_half_width_height,
                        true,
                        true)
    
    _update_surface_contact_for_explicit_grab(center_position_along_surface)
    _update_touch_state()
    _update_action_state()
    
    center_position = center_position_along_surface.target_point
    previous_center_position = center_position
    
    character.position = center_position
    character.start_position = center_position
    character.start_surface = surface
    character.start_position_along_surface = \
            PositionAlongSurface.new(center_position_along_surface)
    character._update_reachable_surfaces(surface)


func _update_contacts() -> void:
    if character.movement_params.bypasses_runtime_physics:
        _update_surface_contact_from_expected_navigation()
    elif is_rounding_corner:
        _update_surface_contact_from_rounded_corner()
    else:
        _update_physics_contacts()


func _update_touch_state() -> void:
    var next_is_touching_floor := false
    var next_is_touching_ceiling := false
    var next_is_touching_wall := false 
    which_wall = SurfaceSide.NONE
    
    for contact in surfaces_to_contacts.values():
        match contact.surface.side:
            SurfaceSide.FLOOR:
                next_is_touching_floor = true
            SurfaceSide.LEFT_WALL, \
            SurfaceSide.RIGHT_WALL:
                next_is_touching_wall = true
                which_wall = contact.surface.side
            SurfaceSide.CEILING:
                next_is_touching_ceiling = true
            _:
                Sc.logger.error()
    
    var next_is_touching_left_wall := which_wall == SurfaceSide.LEFT_WALL
    var next_is_touching_right_wall := which_wall == SurfaceSide.RIGHT_WALL
    
    var next_is_touching_surface := \
            next_is_touching_floor or \
            next_is_touching_ceiling or \
            next_is_touching_wall
    
    var next_just_touched_floor := \
            next_is_touching_floor and !is_touching_floor
    var next_just_stopped_touching_floor := \
            !next_is_touching_floor and is_touching_floor
    
    var next_just_touched_ceiling := \
            next_is_touching_ceiling and !is_touching_ceiling
    var next_just_stopped_touching_ceiling := \
            !next_is_touching_ceiling and is_touching_ceiling
    
    var next_just_touched_wall := \
            next_is_touching_wall and !is_touching_wall
    var next_just_stopped_touching_wall := \
            !next_is_touching_wall and is_touching_wall
    
    var next_just_touched_surface := \
            next_is_touching_surface and !is_touching_surface
    var next_just_stopped_touching_surface := \
            !next_is_touching_surface and is_touching_surface
    
    is_touching_floor = next_is_touching_floor
    is_touching_ceiling = next_is_touching_ceiling
    is_touching_left_wall = next_is_touching_left_wall
    is_touching_right_wall = next_is_touching_right_wall
    is_touching_wall = next_is_touching_wall
    is_touching_surface = next_is_touching_surface
    
    just_touched_floor = \
            next_just_touched_floor or \
            just_touched_floor and !next_just_stopped_touching_floor
    just_stopped_touching_floor = \
            next_just_stopped_touching_floor or \
            just_stopped_touching_floor and !next_just_touched_floor
    
    just_touched_ceiling = \
            next_just_touched_ceiling or \
            just_touched_ceiling and !next_just_stopped_touching_ceiling
    just_stopped_touching_ceiling = \
            next_just_stopped_touching_ceiling or \
            just_stopped_touching_ceiling and !next_just_touched_ceiling
    
    just_touched_wall = \
            next_just_touched_wall or \
            just_touched_wall and !next_just_stopped_touching_wall
    just_stopped_touching_wall = \
            next_just_stopped_touching_wall or \
            just_stopped_touching_wall and !next_just_touched_wall
    
    just_touched_surface = \
            next_just_touched_surface or \
            just_touched_surface and !next_just_stopped_touching_surface
    just_stopped_touching_surface = \
            next_just_stopped_touching_surface or \
            just_stopped_touching_surface and !next_just_touched_surface
    
    # Calculate the sign of a colliding wall's direction.
    toward_wall_sign = \
            (0 if !is_touching_wall else \
            (1 if which_wall == SurfaceSide.RIGHT_WALL else \
            -1))


func _update_physics_contacts() -> void:
    floor_contact = null
    wall_contact = null
    ceiling_contact = null
    
    for surface_contact in surfaces_to_contacts.values():
        surface_contact._is_still_touching = false
    
    for i in character.get_slide_count():
        var collision: KinematicCollision2D = character.get_slide_collision(i)
        var contact_position := collision.position
        var contacted_side: int = \
                Sc.geometry.get_surface_side_for_normal(collision.normal)
        var contacted_tile_map: SurfacesTileMap = collision.collider
        Sc.geometry.get_collision_tile_map_coord(
                _collision_tile_map_coord_result,
                contact_position,
                contacted_tile_map,
                contacted_side == SurfaceSide.FLOOR,
                contacted_side == SurfaceSide.CEILING,
                contacted_side == SurfaceSide.LEFT_WALL,
                contacted_side == SurfaceSide.RIGHT_WALL)
        var contact_position_tile_map_coord := \
                _collision_tile_map_coord_result.tile_map_coord
        var contacted_tile_map_index: int = \
                Sc.geometry.get_tile_map_index_from_grid_coord(
                        contact_position_tile_map_coord,
                        contacted_tile_map)
        var contacted_surface: Surface = \
                character.surface_parser.get_surface_for_tile(
                        contacted_tile_map,
                        contacted_tile_map_index,
                        contacted_side)
        
        if !is_instance_valid(contacted_surface):
            # -  Godot's collision engine has generated a false-positive with
            #    an interior surface.
            # -  This is uncommon.
            continue
        
        var just_started := !surfaces_to_contacts.has(contacted_surface)
        
        if just_started:
            surfaces_to_contacts[contacted_surface] = SurfaceContact.new()
        
        var surface_contact: SurfaceContact = \
                surfaces_to_contacts[contacted_surface]
        surface_contact.surface = contacted_surface
        surface_contact.contact_position = contact_position
        surface_contact.tile_map_coord = contact_position_tile_map_coord
        surface_contact.tile_map_index = contacted_tile_map_index
        surface_contact.position_along_surface.match_current_grab(
                contacted_surface, center_position)
        surface_contact.just_started = just_started
        surface_contact._is_still_touching = true
        
        match contacted_side:
            SurfaceSide.FLOOR:
                floor_contact = surface_contact
            SurfaceSide.LEFT_WALL, \
            SurfaceSide.RIGHT_WALL:
                wall_contact = surface_contact
            SurfaceSide.CEILING:
                ceiling_contact = surface_contact
            _:
                Sc.logger.error()
    
    # Remove any surfaces that are no longer touching.
    for surface_contact in surfaces_to_contacts.values():
        if !surface_contact._is_still_touching:
            surfaces_to_contacts.erase(surface_contact.surface)


func _update_surface_contact_from_rounded_corner() -> void:
    var position_along_surface := \
            _get_position_along_surface_from_rounded_corner()
    _update_surface_contact_for_explicit_grab(position_along_surface)


func _update_surface_contact_from_expected_navigation() -> void:
    var position_along_surface := \
            _get_expected_position_for_bypassing_runtime_physics()
    _update_surface_contact_for_explicit_grab(position_along_surface)


func _get_position_along_surface_from_rounded_corner() -> PositionAlongSurface:
    var surface: Surface
    var contact_position: Vector2
    
    if is_rounding_floor_corner_to_lower_wall:
        if just_changed_surface_while_rounding_corner:
            if grabbed_surface.side == SurfaceSide.FLOOR:
                if center_position.x < grabbed_surface.center.x:
                    surface = grabbed_surface.counter_clockwise_convex_neighbor
                else:
                    surface = grabbed_surface.clockwise_convex_neighbor
            else:
                surface = grabbed_surface
            assert(surface.side == SurfaceSide.LEFT_WALL or \
                    surface.side == SurfaceSide.RIGHT_WALL)
            
            if surface.side == SurfaceSide.LEFT_WALL:
                contact_position = surface.first_point
            else:
                contact_position = surface.last_point
        else:
            surface = grabbed_surface
            assert(surface.side == SurfaceSide.FLOOR)
            
            if center_position.x < surface.center.x:
                contact_position = surface.first_point
            else:
                contact_position = surface.last_point
        
    elif is_rounding_ceiling_corner_to_upper_wall:
        if just_changed_surface_while_rounding_corner:
            if grabbed_surface.side == SurfaceSide.CEILING:
                if center_position.x < grabbed_surface.center.x:
                    surface = grabbed_surface.clockwise_convex_neighbor
                else:
                    surface = grabbed_surface.counter_clockwise_convex_neighbor
            else:
                surface = grabbed_surface
            assert(surface.side == SurfaceSide.LEFT_WALL or \
                    surface.side == SurfaceSide.RIGHT_WALL)
            
            if surface.side == SurfaceSide.LEFT_WALL:
                contact_position = surface.last_point
            else:
                contact_position = surface.first_point
        else:
            surface = grabbed_surface
            assert(surface.side == SurfaceSide.CEILING)
            
            if center_position.x < surface.center.x:
                contact_position = surface.last_point
            else:
                contact_position = surface.first_point
        
    elif is_rounding_wall_corner_to_lower_ceiling:
        if just_changed_surface_while_rounding_corner:
            if grabbed_surface.side == SurfaceSide.LEFT_WALL:
                surface = grabbed_surface.clockwise_convex_neighbor
            elif grabbed_surface.side == SurfaceSide.RIGHT_WALL:
                surface = grabbed_surface.counter_clockwise_convex_neighbor
            else:
                surface = grabbed_surface
            assert(surface.side == SurfaceSide.CEILING)
            
            if center_position.x < surface.center.x:
                contact_position = surface.last_point
            else:
                contact_position = surface.first_point
        else:
            surface = grabbed_surface
            assert(surface.side == SurfaceSide.LEFT_WALL or \
                    surface.side == SurfaceSide.RIGHT_WALL)
            
            if surface.side == SurfaceSide.LEFT_WALL:
                contact_position = surface.last_point
            else:
                contact_position = surface.first_point
        
    elif is_rounding_wall_corner_to_upper_floor:
        if just_changed_surface_while_rounding_corner:
            if grabbed_surface.side == SurfaceSide.LEFT_WALL:
                surface = grabbed_surface.counter_clockwise_convex_neighbor
            elif grabbed_surface.side == SurfaceSide.RIGHT_WALL:
                surface = grabbed_surface.clockwise_convex_neighbor
            else:
                surface = grabbed_surface
            assert(surface.side == SurfaceSide.FLOOR)
            
            if center_position.x < surface.center.x:
                contact_position = surface.first_point
            else:
                contact_position = surface.last_point
        else:
            surface = grabbed_surface
            assert(surface.side == SurfaceSide.LEFT_WALL or \
                    surface.side == SurfaceSide.RIGHT_WALL)
            
            if surface.side == SurfaceSide.LEFT_WALL:
                contact_position = surface.first_point
            else:
                contact_position = surface.last_point
        
    else:
        Sc.logger.error()
        return null
    
    return PositionAlongSurfaceFactory.create_position_offset_from_target_point(
            contact_position,
            surface,
            character.movement_params.collider_half_width_height,
            true)


func _get_expected_position_for_bypassing_runtime_physics() -> \
        PositionAlongSurface:
    return character.navigation_state.expected_position_along_surface if \
            character.navigation_state.is_currently_navigating else \
            character.navigator.get_previous_destination()


func _update_surface_contact_for_explicit_grab(
        position_along_surface: PositionAlongSurface) -> void:
    var surface := position_along_surface.surface
    var side := surface.side
    var contact_position := \
            position_along_surface.target_projection_onto_surface
    var tile_map := surface.tile_map
    
    Sc.geometry.get_collision_tile_map_coord(
            _collision_tile_map_coord_result,
            contact_position,
            tile_map,
            side == SurfaceSide.FLOOR,
            side == SurfaceSide.CEILING,
            side == SurfaceSide.LEFT_WALL,
            side == SurfaceSide.RIGHT_WALL)
    var tile_map_coord := _collision_tile_map_coord_result.tile_map_coord
    var tile_map_index: int = Sc.geometry.get_tile_map_index_from_grid_coord(
            tile_map_coord,
            tile_map)
    var just_started := \
            !is_instance_valid(surface_grab) or \
            surface_grab.surface != surface
    
    # Don't create a new instance each frame if we can re-use the old one.
    var surface_contact := \
            surface_grab if \
            is_instance_valid(surface_grab) else \
            SurfaceContact.new()
    surface_contact.surface = surface
    surface_contact.contact_position = contact_position
    surface_contact.tile_map_coord = tile_map_coord
    surface_contact.tile_map_index = tile_map_index
    surface_contact.position_along_surface = position_along_surface
    surface_contact.just_started = just_started
    surface_contact._is_still_touching = true
    
    floor_contact = null
    wall_contact = null
    ceiling_contact = null
    match side:
        SurfaceSide.FLOOR:
            floor_contact = surface_contact
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            wall_contact = surface_contact
        SurfaceSide.CEILING:
            ceiling_contact = surface_contact
        _:
            Sc.logger.error()
    
    if just_started:
        surfaces_to_contacts.clear()
        surfaces_to_contacts[surface_contact.surface] = surface_contact


func _update_action_state() -> void:
    _update_horizontal_direction()
    _update_grab_trigger_state()
    _update_rounding_corner_state()
    _update_grab_state()
    
    if is_rounding_corner:
        _update_surface_contact_from_rounded_corner()
        _update_touch_state()
    
    _update_grab_contact()


func _update_horizontal_direction() -> void:
    # Flip the horizontal direction of the animation according to which way the
    # character is facing.
    if character.actions.pressed_face_right:
        horizontal_facing_sign = 1
    elif character.actions.pressed_face_left:
        horizontal_facing_sign = -1
    elif character.actions.pressed_right:
        horizontal_facing_sign = 1
    elif character.actions.pressed_left:
        horizontal_facing_sign = -1
    elif is_grabbing_wall:
        horizontal_facing_sign = toward_wall_sign
    
    if character.actions.pressed_right:
        horizontal_acceleration_sign = 1
    elif character.actions.pressed_left:
        horizontal_acceleration_sign = -1
    else:
        horizontal_acceleration_sign = 0
    
    is_facing_wall = \
            (which_wall == SurfaceSide.RIGHT_WALL and \
                    horizontal_facing_sign > 0) or \
            (which_wall == SurfaceSide.LEFT_WALL and \
                    horizontal_facing_sign < 0)
    is_pressing_into_wall = \
            (which_wall == SurfaceSide.RIGHT_WALL and \
                    character.actions.pressed_right) or \
            (which_wall == SurfaceSide.LEFT_WALL and \
                    character.actions.pressed_left)
    is_pressing_away_from_wall = \
            (which_wall == SurfaceSide.RIGHT_WALL and \
                    character.actions.pressed_left) or \
            (which_wall == SurfaceSide.LEFT_WALL and \
                    character.actions.pressed_right)


func _update_grab_trigger_state() -> void:
    var facing_into_wall_and_pressing_up: bool = \
            character.actions.pressed_up and is_facing_wall
    var facing_into_wall_and_pressing_grab: bool = \
            character.actions.pressed_grab and is_facing_wall
    var touching_concave_floor_and_pressing_down: bool = \
            character.actions.pressed_down and \
            is_touching_floor and \
            is_touching_wall and \
            (floor_contact.surface.clockwise_concave_neighbor == \
                    wall_contact or \
            floor_contact.surface.counter_clockwise_concave_neighbor == \
                    wall_contact)
    
    var is_pressing_floor_grab_input: bool = \
            (character.actions.pressed_down or \
            character.actions.pressed_grab)
    var is_pressing_ceiling_grab_input: bool = \
            (character.actions.pressed_up and \
                    !character.actions.pressed_down or \
            character.actions.pressed_grab)
    var is_pressing_wall_grab_input := \
            (is_pressing_into_wall or \
            facing_into_wall_and_pressing_up or \
            facing_into_wall_and_pressing_grab) and \
            !is_pressing_away_from_wall
    var is_pressing_ceiling_release_input: bool = \
            character.actions.pressed_down and \
            !character.actions.pressed_up and \
            !character.actions.pressed_grab
    var is_pressing_wall_release_input := \
            is_pressing_away_from_wall and \
            !is_pressing_into_wall
    var is_pressing_fall_through_input: bool = \
            character.actions.pressed_down and \
            character.actions.just_pressed_jump
    
    var standard_is_triggering_ceiling_grab: bool = \
            is_touching_ceiling and \
            is_pressing_ceiling_grab_input
    var standard_is_triggering_wall_grab := \
            is_touching_wall and \
            is_pressing_wall_grab_input and \
            !touching_concave_floor_and_pressing_down
    var standard_is_triggering_explicit_floor_grab: bool = \
            is_touching_floor and \
            is_pressing_floor_grab_input and \
            !is_pressing_wall_grab_input
    
    var current_grabbed_side := \
            grabbed_surface.side if \
            is_instance_valid(grabbed_surface) else \
            SurfaceSide.NONE
    var previous_grabbed_side := \
            previous_grabbed_surface.side if \
            is_instance_valid(previous_grabbed_surface) else \
            SurfaceSide.NONE
    
    var are_current_and_previous_surfaces_convex_neighbors := \
            is_instance_valid(grabbed_surface) and \
            is_instance_valid(previous_grabbed_surface) and \
            (previous_grabbed_surface.clockwise_convex_neighbor == \
                    grabbed_surface or \
            previous_grabbed_surface.counter_clockwise_convex_neighbor == \
                    grabbed_surface)
    
    var is_facing_previous_wall := \
            (previous_grabbed_side == SurfaceSide.RIGHT_WALL and \
                    horizontal_facing_sign > 0) or \
            (previous_grabbed_side == SurfaceSide.LEFT_WALL and \
                    horizontal_facing_sign < 0)
    var is_pressing_into_previous_wall: bool = \
            (previous_grabbed_side == SurfaceSide.RIGHT_WALL and \
                    character.actions.pressed_right) or \
            (previous_grabbed_side == SurfaceSide.LEFT_WALL and \
                    character.actions.pressed_left)
    var is_pressing_away_from_previous_wall: bool = \
            (previous_grabbed_side == SurfaceSide.RIGHT_WALL and \
                    character.actions.pressed_left) or \
            (previous_grabbed_side == SurfaceSide.LEFT_WALL and \
                    character.actions.pressed_right)
    var facing_into_previous_wall_and_pressing_up: bool = \
            character.actions.pressed_up and is_facing_previous_wall
    var facing_into_previous_wall_and_pressing_grab: bool = \
            character.actions.pressed_grab and is_facing_previous_wall
    var is_pressing_previous_wall_grab_input := \
            (is_pressing_into_previous_wall or \
            facing_into_previous_wall_and_pressing_up or \
            facing_into_previous_wall_and_pressing_grab) and \
            !is_pressing_away_from_previous_wall
    
    var is_still_triggering_wall_grab_since_rounding_corner_to_floor := \
            current_grabbed_side == SurfaceSide.FLOOR and \
            (previous_grabbed_side == SurfaceSide.LEFT_WALL or \
            previous_grabbed_side == SurfaceSide.RIGHT_WALL) and \
            are_current_and_previous_surfaces_convex_neighbors and \
            is_pressing_previous_wall_grab_input
    var is_still_triggering_wall_grab_since_rounding_corner_to_ceiling := \
            current_grabbed_side == SurfaceSide.CEILING and \
            (previous_grabbed_side == SurfaceSide.LEFT_WALL or \
            previous_grabbed_side == SurfaceSide.RIGHT_WALL) and \
            are_current_and_previous_surfaces_convex_neighbors and \
            is_pressing_previous_wall_grab_input
    var is_still_triggering_floor_grab_since_rounding_corner_to_wall := \
            (current_grabbed_side == SurfaceSide.LEFT_WALL or \
            current_grabbed_side == SurfaceSide.RIGHT_WALL) and \
            previous_grabbed_side == SurfaceSide.FLOOR and \
            are_current_and_previous_surfaces_convex_neighbors and \
            is_pressing_floor_grab_input
    var is_still_triggering_ceiling_grab_since_rounding_corner_to_wall := \
            (current_grabbed_side == SurfaceSide.LEFT_WALL or \
            current_grabbed_side == SurfaceSide.RIGHT_WALL) and \
            previous_grabbed_side == SurfaceSide.CEILING and \
            are_current_and_previous_surfaces_convex_neighbors and \
            is_pressing_ceiling_grab_input
    
    is_triggering_explicit_floor_grab = \
            standard_is_triggering_explicit_floor_grab or \
            is_still_triggering_wall_grab_since_rounding_corner_to_floor
    is_triggering_ceiling_grab = \
            standard_is_triggering_ceiling_grab or \
            is_still_triggering_wall_grab_since_rounding_corner_to_ceiling
    is_triggering_wall_grab = \
            (standard_is_triggering_wall_grab or \
            is_still_triggering_floor_grab_since_rounding_corner_to_wall or \
            is_still_triggering_ceiling_grab_since_rounding_corner_to_wall) and \
            !is_triggering_ceiling_grab
    
    is_triggering_ceiling_release = \
            is_touching_ceiling and \
            is_pressing_ceiling_release_input and \
            !is_triggering_ceiling_grab
    is_triggering_wall_release = \
            is_touching_wall and \
            is_pressing_wall_release_input and \
            !is_triggering_wall_grab
    is_triggering_fall_through = \
            is_touching_floor and \
            is_pressing_fall_through_input


func _update_rounding_corner_state() -> void:
    var half_width: float = \
            character.movement_params.collider_half_width_height.x
    var half_height: float = \
            character.movement_params.collider_half_width_height.y
    
    is_rounding_floor_corner_to_lower_wall = \
            is_grabbing_floor and \
            is_triggering_explicit_floor_grab and \
            character.movement_params.can_grab_walls and \
            (center_position.x <= grabbed_surface.first_point.x or \
            center_position.x >= grabbed_surface.last_point.x)
    just_changed_to_lower_wall_while_rounding_floor_corner = \
            is_rounding_floor_corner_to_lower_wall and \
            (center_position.x + half_width <= \
                    grabbed_surface.first_point.x or \
            center_position.x - half_width >= \
                    grabbed_surface.last_point.x)
    
    is_rounding_ceiling_corner_to_upper_wall = \
            is_grabbing_ceiling and \
            is_triggering_ceiling_grab and \
            character.movement_params.can_grab_walls and \
            (center_position.x <= grabbed_surface.last_point.x or \
            center_position.x >= grabbed_surface.first_point.x)
    just_changed_to_upper_wall_while_rounding_ceiling_corner = \
            is_rounding_ceiling_corner_to_upper_wall and \
            (center_position.x + half_width <= \
                    grabbed_surface.last_point.x or \
            center_position.x - half_width >= \
                    grabbed_surface.first_point.x)
    
    is_rounding_wall_corner_to_lower_ceiling = \
            is_grabbing_wall and \
            is_triggering_wall_grab and \
            character.movement_params.can_grab_ceilings and \
            center_position.y >= grabbed_surface.bounding_box.end.y
    just_changed_to_lower_ceiling_while_rounding_wall_corner = \
            is_rounding_wall_corner_to_lower_ceiling and \
            center_position.y - half_width >= \
                    grabbed_surface.bounding_box.end.y
    
    is_rounding_wall_corner_to_upper_floor = \
            is_grabbing_wall and \
            is_triggering_wall_grab and \
            character.movement_params.can_grab_floors and \
            center_position.y <= grabbed_surface.bounding_box.position.y
    just_changed_to_upper_floor_while_rounding_wall_corner = \
            is_rounding_wall_corner_to_upper_floor and \
            center_position.y + half_width <= \
                    grabbed_surface.bounding_box.position.y
    
    is_rounding_corner = \
            is_rounding_floor_corner_to_lower_wall or \
            is_rounding_ceiling_corner_to_upper_wall or \
            is_rounding_wall_corner_to_lower_ceiling or \
            is_rounding_wall_corner_to_upper_floor
    just_changed_surface_while_rounding_corner = \
            just_changed_to_lower_wall_while_rounding_floor_corner or \
            just_changed_to_upper_wall_while_rounding_ceiling_corner or \
            just_changed_to_lower_ceiling_while_rounding_wall_corner or \
            just_changed_to_upper_floor_while_rounding_wall_corner
    
    var is_rounding_right_wall_corner := \
            (is_rounding_wall_corner_to_lower_ceiling or \
            is_rounding_wall_corner_to_upper_floor) and \
            grabbed_surface.side == SurfaceSide.RIGHT_WALL
    var is_rounding_left_corner_of_horizontal_surafce := \
            (is_rounding_floor_corner_to_lower_wall or \
            is_rounding_ceiling_corner_to_upper_wall) and \
            center_position.x <= grabbed_surface.center.x
    is_rounding_left_corner = \
            is_rounding_right_wall_corner or \
            is_rounding_left_corner_of_horizontal_surafce


func _update_grab_state() -> void:
    # Whether we are grabbing a ceiling.
    var standard_is_grabbing_ceiling: bool = \
            character.movement_params.can_grab_ceilings and \
            (is_touching_ceiling or \
                    is_rounding_ceiling_corner_to_upper_wall) and \
            (is_grabbing_ceiling or \
                    is_triggering_ceiling_grab) and \
            (!is_triggering_wall_grab or \
                    is_triggering_ceiling_grab)
    var next_is_grabbing_ceiling := \
            (standard_is_grabbing_ceiling or \
            just_changed_to_lower_ceiling_while_rounding_wall_corner) and \
            !just_changed_to_upper_wall_while_rounding_ceiling_corner
    
    # Whether we are grabbing a wall.
    var standard_is_grabbing_wall: bool = \
            character.movement_params.can_grab_walls and \
            (is_touching_wall or \
                    is_rounding_wall_corner_to_lower_ceiling or \
                    is_rounding_wall_corner_to_upper_floor) and \
            (is_grabbing_wall or \
                    is_triggering_wall_grab) and \
            !is_triggering_explicit_floor_grab and \
            !is_triggering_ceiling_grab
    var next_is_grabbing_wall := \
            (standard_is_grabbing_wall or \
            just_changed_to_lower_wall_while_rounding_floor_corner or \
            just_changed_to_upper_wall_while_rounding_ceiling_corner) and \
            !just_changed_to_upper_floor_while_rounding_wall_corner and \
            !just_changed_to_lower_ceiling_while_rounding_wall_corner and \
            !next_is_grabbing_ceiling
    
    # Whether we are grabbing a floor.
    var standard_is_grabbing_floor: bool = \
            is_touching_floor or \
            is_rounding_floor_corner_to_lower_wall
    var next_is_grabbing_floor := \
            (standard_is_grabbing_floor or \
            just_changed_to_upper_floor_while_rounding_wall_corner) and \
            !just_changed_to_lower_wall_while_rounding_floor_corner and \
            !next_is_grabbing_wall and \
            !next_is_grabbing_ceiling
    
    var next_is_grabbing_left_wall := \
            next_is_grabbing_wall and \
            ((is_rounding_corner and \
                    center_position.x > grabbed_surface.center.x) or \
            (!is_rounding_corner and \
                    is_touching_left_wall))
    var next_is_grabbing_right_wall := \
            next_is_grabbing_wall and \
            ((is_rounding_corner and \
                    center_position.x < grabbed_surface.center.x) or \
            (!is_rounding_corner and \
                    is_touching_right_wall))
    
    var next_is_grabbing_surface := \
            next_is_grabbing_floor or \
            next_is_grabbing_ceiling or \
            next_is_grabbing_wall
    
    var next_just_grabbed_floor := \
            next_is_grabbing_floor and !is_grabbing_floor
    var next_just_stopped_grabbing_floor := \
            !next_is_grabbing_floor and is_grabbing_floor
    
    var next_just_grabbed_ceiling := \
            next_is_grabbing_ceiling and !is_grabbing_ceiling
    var next_just_stopped_grabbing_ceiling := \
            !next_is_grabbing_ceiling and is_grabbing_ceiling
    
    var next_just_grabbed_left_wall := \
            next_is_grabbing_left_wall and !is_grabbing_left_wall
    var next_just_stopped_grabbing_left_wall := \
            !next_is_grabbing_left_wall and is_grabbing_left_wall
    
    var next_just_grabbed_right_wall := \
            next_is_grabbing_right_wall and !is_grabbing_right_wall
    var next_just_stopped_grabbing_right_wall := \
            !next_is_grabbing_right_wall and is_grabbing_right_wall
    
    var next_just_entered_air := \
            !next_is_grabbing_surface and is_grabbing_surface
    var next_just_left_air := \
            next_is_grabbing_surface and !is_grabbing_surface
    
    is_grabbing_floor = next_is_grabbing_floor
    is_grabbing_ceiling = next_is_grabbing_ceiling
    is_grabbing_left_wall = next_is_grabbing_left_wall
    is_grabbing_right_wall = next_is_grabbing_right_wall
    is_grabbing_wall = is_grabbing_left_wall or is_grabbing_right_wall
    is_grabbing_surface = next_is_grabbing_surface
    
    just_grabbed_floor = \
            next_just_grabbed_floor or \
            just_grabbed_floor and !next_just_stopped_grabbing_floor
    just_stopped_grabbing_floor = \
            next_just_stopped_grabbing_floor or \
            just_stopped_grabbing_floor and !next_just_grabbed_floor
    
    just_grabbed_ceiling = \
            next_just_grabbed_ceiling or \
            just_grabbed_ceiling and !next_just_stopped_grabbing_ceiling
    just_stopped_grabbing_ceiling = \
            next_just_stopped_grabbing_ceiling or \
            just_stopped_grabbing_ceiling and !next_just_grabbed_ceiling
    
    just_grabbed_left_wall = \
            next_just_grabbed_left_wall or \
            just_grabbed_left_wall and !next_just_stopped_grabbing_left_wall
    just_stopped_grabbing_left_wall = \
            next_just_stopped_grabbing_left_wall or \
            just_stopped_grabbing_left_wall and !next_just_grabbed_left_wall
    
    just_grabbed_right_wall = \
            next_just_grabbed_right_wall or \
            just_grabbed_right_wall and !next_just_stopped_grabbing_right_wall
    just_stopped_grabbing_right_wall = \
            next_just_stopped_grabbing_right_wall or \
            just_stopped_grabbing_right_wall and !next_just_grabbed_right_wall
    
    just_entered_air = \
            next_just_entered_air or \
            just_entered_air and !next_just_left_air
    just_left_air = \
            next_just_left_air or \
            just_left_air and !next_just_entered_air
    
    just_grabbed_surface = \
            just_grabbed_floor or \
            just_grabbed_ceiling or \
            just_grabbed_left_wall or \
            just_grabbed_right_wall
    
    if is_grabbing_floor:
        surface_type = SurfaceType.FLOOR
    elif is_grabbing_wall:
        surface_type = SurfaceType.WALL
    elif is_grabbing_ceiling:
        surface_type = SurfaceType.CEILING
    else:
        surface_type = SurfaceType.AIR
    
    # Whether we should fall through fall-through floors.
    match surface_type:
        SurfaceType.FLOOR:
            is_descending_through_floors = is_triggering_fall_through
        SurfaceType.WALL:
            is_descending_through_floors = character.actions.pressed_down
        SurfaceType.CEILING:
            is_descending_through_floors = false
        SurfaceType.AIR, \
        SurfaceType.OTHER:
            is_descending_through_floors = character.actions.pressed_down
        _:
            Sc.logger.error()
    
    # FIXME: ------- Add support for an ascend-through ceiling input.
    # Whether we should ascend-up through jump-through ceilings.
    is_ascending_through_ceilings = \
            !character.movement_params.can_grab_ceilings or \
                (!is_grabbing_ceiling and true)
    
    # Whether we should fall through fall-through floors.
    is_grabbing_walk_through_walls = \
            character.movement_params.can_grab_walls and \
                (is_grabbing_wall or \
                        character.actions.pressed_up)


func _update_grab_contact() -> void:
    var previous_grab_position := grab_position
    var previous_grabbed_tile_map := grabbed_tile_map
    var previous_grab_position_tile_map_coord := grab_position_tile_map_coord
    
    surface_grab = null
    
    if is_grabbing_surface:
        for surface in surfaces_to_contacts:
            if surface.side == SurfaceSide.FLOOR and \
                            is_grabbing_floor or \
                    surface.side == SurfaceSide.LEFT_WALL and \
                            is_grabbing_left_wall or \
                    surface.side == SurfaceSide.RIGHT_WALL and \
                            is_grabbing_right_wall or \
                    surface.side == SurfaceSide.CEILING and \
                            is_grabbing_ceiling:
                surface_grab = surfaces_to_contacts[surface]
                break
        assert(is_instance_valid(surface_grab))
        
        grab_position = surface_grab.contact_position
        grabbed_tile_map = surface_grab.surface.tile_map
        grab_position_tile_map_coord = surface_grab.tile_map_coord
        var next_grabbed_surface: Surface = surface_grab.surface
        PositionAlongSurface.copy(
                center_position_along_surface,
                surface_grab.position_along_surface)
        PositionAlongSurface.copy(
                last_position_along_surface,
                center_position_along_surface)
        
        just_changed_grab_position = \
                just_changed_grab_position or \
                (just_left_air or \
                        grab_position != previous_grab_position)
        
        just_changed_tile_map = \
                just_changed_tile_map or \
                (just_left_air or \
                        grabbed_tile_map != previous_grabbed_tile_map)
        
        just_changed_tile_map_coord = \
                just_changed_tile_map_coord or \
                (just_left_air or \
                        grab_position_tile_map_coord != \
                        previous_grab_position_tile_map_coord)
        
        just_changed_surface = \
                just_changed_surface or \
                (just_left_air or \
                        next_grabbed_surface != grabbed_surface)
        if just_changed_surface:
            previous_grabbed_surface = \
                    previous_grabbed_surface if \
                    next_grabbed_surface == grabbed_surface else \
                    grabbed_surface
        grabbed_surface = next_grabbed_surface
        
    else:
        if just_entered_air:
            just_changed_grab_position = true
            just_changed_tile_map = true
            just_changed_tile_map_coord = true
            just_changed_surface = true
            previous_grabbed_surface = \
                    grabbed_surface if \
                    is_instance_valid(grabbed_surface) else \
                    previous_grabbed_surface
        
        grab_position = Vector2.INF
        grabbed_tile_map = null
        grab_position_tile_map_coord = Vector2.INF
        grabbed_surface = null
        center_position_along_surface.reset()


func _get_contact_count() -> int:
    return surfaces_to_contacts.size()
