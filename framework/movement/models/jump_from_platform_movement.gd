extends Movement
class_name JumpFromPlatformMovement

const MovementCalcOverallParams := preload("res://framework/movement/models/movement_calculation_overall_params.gd")

# FIXME: SUB-MASTER LIST ***************
# - Add support for specifying a required min/max end-x-velocity.
#   - More notes in the backtracking method.
# - Test support for specifying a required min/max end-x-velocity.
# 
# - LEFT OFF HERE: Resolve/debug all left-off commented-out places.
# - LEFT OFF HERE: Check for other obvious false negative edges.
# 
# - LEFT OFF HERE: Implement/test edge-traversal movement:
#   - Test the logic for moving along a path.
#   - Add support for sending the CPU to a click target (configured in the specific level).
#   - Add support for picking random surfaces or points-in-space to move the CPU to; resetting
#        to a new point after the CPU reaches the old point.
#     - Implement this as an alternative to ClickToNavigate (actually, support both running at the
#       same time).
#     - It will need to listen for when the navigator has reached the destination though (make sure
#       that signal is emitted).
# - LEFT OFF HERE: Create a demo level to showcase lots of interesting edges.
# - LEFT OFF HERE: Check for other obvious false negative edges.
# - LEFT OFF HERE: Debug why discrete movement trajectories are incorrect.
#   - Discrete trajectories are definitely peaking higher; should we cut the jump button sooner?
#   - Not considering continous max vertical velocity might contribute to discrete vertical
#     movement stopping short.
# - LEFT OFF HERE: Debug/stress-test intermediate collision scenarios.
#   - After fixing max vertical velocity, is there anything else I can boost?
# - LEFT OFF HERE: Debug why check_instructions_for_collision fails with collisions (render better annotations?).
# - LEFT OFF HERE: Add squirrel animation.
# 
# - Debugging:
#   - Would it help to add some quick and easy annotation helpers for temp debugging that I can access on global (or wherever) and just tell to render dots/lines/circles?
#   - Then I could use that to render all sorts of temp calculation stuff from this file.
#   - Add an annotation for tracing the players recent center positions.
#   - Try rendering a path for trajectory that's closer to the calculations for parabolic motion instead of the resulting instruction positions?
#     - Might help to see the significance of the difference.
#     - Might be able to do this with smaller step sizes?
# 
# - Problem: What if we hit a ceiling surface (still moving upwards)?
#   - We'll set a constraint to either side.
#   - Then we'll likely need to backtrack to use a bigger jump height.
#   - On the backtracking traversal, we'll hit the same surface again.
#     - Solution: We should always be allowed to hit ceiling surfaces again.
#       - Which surfaces _aren't_ we allowed to hit again?
#         - floor, left_wall, right_wall
#       - Important: Double-check that if collision clips a static-collidable corner, that the
#         correct surface is returned
# - Problem: If we allow hitting a ceiling surface repeatedly, what happens if a jump ascent cannot
#   get around it (cannot move horizontally far enough during the ascent)?
#   - Solution: Afer calculating constraints for a surface collision, if it's a ceiling surface,
#     check whether the time to move horizontally exceeds the time to move upward for either
#     constraint. If so, abandon that traversal (remove the constraint from the array before
#     calling the sub function).
# - Optimization: We should never consider increased-height backtracking from hitting a ceiling
#   surface.
# 
# - Create a pause menu and a level switcher.
# - Create some sort of configuration for specifying a level as well as the set of annotations to use.
#   - Actually use this from the menu's level switcher.
#   - Or should the level itself specify which annotations to use?
# - Adapt one of the levels to just render a human player and then the annotations for all edges
#   that our algorithm thinks the human player can traverse.
#   - Try to render all of the interesting edge pairs that I think I should test for.
# 
# - Step through and double-check each return value parameter individually through the recursion, and each input parameter.
# 
# - Optimize a bit for collisions with vertical surfaces:
#   - For the top constraint, change the constraint position to instead use the far side of the
#     adjacent top-side/floor surface.
#   - This probably means I should store adjacent Surfaces when originally parsing the Surfaces.
# - Step through all parts and re-check for correctness.
# - Account for half-width/height offset needed to clear the edge of B (if possible).
# - Also, account for the half-width/height offset needed to not fall onto A.
# - Include a margin around constraints and land position.
# - Allow for the player to bump into walls/ceiling if they could still reach the land point
#   afterward (will need to update logic to not include margin when accounting for these hits).
# - Update the instructions calculations to consider actual discrete timesteps rather than
#   using continuous algorithms.
# - Share per-frame state updates logic between the instruction calculations and actual Player
#   movements.
# - Problem: We need to make sure that we still have enough momementum left once we hit the target
#   position to actually cause us to grab on to the target surface.
#   - Solution: Add support for ensuring a minimum normal-direction speed at the end of the jump.
#     - Faster is probably always better, since efficient/quick movements are better.
# 
# - Problem: All of the edge calculations will allow the slow-ascent gravity to also be used for
#   the downward portion of the jump.
#   - Either update Player controllers to also allow that,
#   - or update all relevant edge calculation logic.
# 
# - Make some diagrams in InkScape with surfaces, trajectories, and constraints to demonstrate
#   algorithm traversal
#   - Label/color-code parts to demonstrate separate traversal steps
# - Make the 144-cell diagram in InkScape and add to docs.
# - Storing possibly 9 edges from A to B.
# 
# FIXME: C:
# - Set the destination_constraint min_velocity_x and max_velocity_x at the start, in order to
#   latch onto the target surface.
#   - Also add support for specifying min/max y velocities for this?
# 
# FIXME: B:
# - Should we more explicity re-use all horizontal steps from before the jump button was released?
#   - It might simplify the logic for checking for previously collided surfaces, and make things
#     more efficient.
# 
# FIXME: B: Check if we need to update following constraints when creating a new one:
# - Unfortunately, it is possible that the creation of a new intermediate constraint could
#   invalidate the actual_velocity_x for the following constraint(s). A fix for this would be
#   to first recalculate the min/max x velocities for all following constraints in forward
#   order, and then recalculate the actual x velocity for all following constraints in reverse
#   order.
# 
# FIXME: B: 
# - Make edge-calc annotations usable at run time, by clicking on the start and end positions to check.
# 




# FIXME: LEFT OFF HERE: -------------------------------------------------A
# 
# #########
# 
# - Try adding other edges now:
#   - 
# 
# - Add some sort of heuristic to choose when to go with smaller or larger velocity end during
#   horizontal step calc.
#   - The alternative, is to once again flip the order we calculate steps, so that we base all
#     steps off of minimizing the x velocity at the destination.
#     - :/ We might want to do that anyway though, to give us more flexibility later when we want
#       to be able to specify a given non-zero target end velocity.
# 
# - Should I move some of the horizontal movement functions from constraint_utils to
#   horizontal_movement_utils?
# 
# - Can I render something in the annotations (or in the console output) like the constraint
#   position or the surface end positions, in order to make it easier to quickly set a breakpoint
#   to match the corresponding step?
# 
# - Debug, debug, debug...
# 
# - Additional_high_constraint_position breakpoint is happening three times??
#   - Should I move the fail-because-we've-been-here-before logic from looking at steps+surfaces+heights to here?
# 
# - Should we somehow ensure that jump height is always bumped up at least enough to cover the
#   extra distance of constraint offsets? 
#   - Since jumping up to a destination, around the other edge of the platform (which has the
#     constraint offset), seems like a common use-case, this would probably be a useful optimization.
#   - [This is important, since the first attempt at getting to the top-right constraint always fails, since it requires a _slightly_ higher jump, and we want it to instead succeed.]
# 
# - There is a problem with my approach for using time_to_get_to_destination_from_constraint.
#   time-to-get-to-intermediate-constraint-from-constraint could matter a lot too. But maybe this
#   is infrequent enough that I don't care? At least document this limitation (in code and README).
# 
# - Add logic to ignore a constraint when the horizontal steps leading up to it would have found
#   another collision.
#   - Because changing trajectory for the earlier collision is likely to invalidate the later
#     collision.
#   - In this case, the recursive call that found the additional, earlier collision will need to
#     also then calculate all steps from this collision to the end?
# 
# - Fix pixel-perfect scaling/aliasing when enlarging screen and doing camera zoom.
#   - Only support whole-number multiples somehow?
# 
# - When backtracking, re-use all steps that finish before releasing the jump button.
# 
# - Add a translation to the on-wall cat animations, so that they are all a bit lower; the cat's
#   head should be about the same position as the corresponding horizontal pose that collided, and
#   the bottom should fall from there.
# 
# - Add support for detecting invalid origin/destination positions (due to pre-existing collisions
#   with nearby surfaces).
#   - Shouldn't matter for convex neighbor surfaces though.
#   - And then add support for correcting the origin/destination position to avoid the collision.
#     - When a pre-existing collision is detected, look at the surface side direction.
#     - If parallel to the origin/destination surface, give up.
#     - If perpendicular, then offset the position to where the player would rest against the
#       surface, and check whether that position is still valid along the origin/destination
#       surface.
# 
# - Render a legend:
#   - x: point of collision
#   - outline: player boundary at point of collision
#   - open circles: start or end constraints
#   - plus: left/right button start
#   - minus: left/right button end
#   - asterisk: jump button end
#   - diamond: 
#   - BT: 
#   - RF: 
# 
# - Polish description of approach in the README.
#   - In general, a guiding heuristic in these calculations is to minimize movement. So, through
#     each constraint (step-end), we try to minimize the horizontal speed of the movement at that
#     point.
# 
# - Try to fix DrawUtils dashed polylines.
# 
# - Think through and maybe fix the function in constraint utils for accounting for max-speed vs
#   min/max for valid next step?
# 
# 
# - Collision calculation annotator:
#   - Would it be worth adding support to zoom and pan the camera to the current collision?
#     - Maybe this could be toggleable via clicking a button in the tree view?
#     - Would definitely want to animate the zoom.
#     - Probably also need to change the camera translation.
#       - Probably can just calculate the offset from the player to the collision, and use that to
#         manually assign an offset to the camera.
#       - Would also need to animate this translation.
# 


# FIXME: LEFT OFF HERE: ---------------------------------------------------------A
# FIXME: -----------------------------
# 
# ---  ---
# 
# - Fix some constraint calc logic for the case of starting a new navigation while in the air
#   (origin does not correspond to a surface, or to an x-velocity in the expected direction)
#   (currently breaks assertion at the end of _update_constraint_velocity_and_time).
# 
# - Fix issue where jumping around edge isn't going far enough. It's clipping the corner.
# 
# ---  ---
# 
# - Finish remaining surface-closest-point-jump-off calculation cases.
#   - Also, maybe still not quite far enough with the offset?
# 
# - Fix any remaining Navigator movement issues.
# - Fix performance.
#   - Should I almost never be actually storing things in Pool arrays? It seems like I mostly end
#     up passing them around as arguments to functions, to they get copied as values...
# 
# - Debug why this edge calculation generates 35 steps...
#   - test_level_long_rise
#   - from top-most floor to bottom-most (wide) floor, on the right side
# 
# - Fix frame collision detection...
#   - Seeing pre-existing collisions when jumping from walls.
#   - Fix collision-detection errors from logs.
# 
# ---  ---
# 
# - Update navigation to do some additional on-the-fly edge calculations.
#   - Only limit this to a few additional potential edges along the path.
#   - The idea is that the edges tend to produce very unnatural composite trajectories (similar to
#     using perpendicular Manhatten distance routes instead of more diagonal routes).
#   >- Basically, try jumping from earlier on any given surface.
#     - It may be hard to know exactly where along a surface to try jumping from though...
#     - Should probably just use some simple heuristic and just give up when they fail with
#       false-positive rates.
#   >- Also, update velocity_start for these on-the-fly edges to be more intelligent.
# 
# - Update navigator to force player state to match expected edge start state.
#   - Configurable.
#   - Both position and velocity.
# - Add support for forcing state during edge movement to match what is expected from the original edge calculations.
#   - Configurable.
#   - Apply this to both position and velocity.
#   - Also, allow for this to use a weighted average of the expected state vs the actual state from normal run-time.
#   - Also, add a warning message when the player is too far from what's expected.
# 
# - Update edge-calculations to support variable velocity_start_x values.
#   - Allow for up-front edge calculation to use any desired velocity_start_x between
#     -max_horizontal_speed_default and max_horizontal_speed_default.
#   - This is probably a decent approximation, since we can usually assume that the ramp-up
#     distance to get from 0 to max-x-speed on the floor is small enough that we can ignore it.
#   - We could probably actually do an even better job by limiting the range for velocity_start_x
#     for floor-surface-end-jump-off-points to be between either -max_horizontal_speed_default and
#     0 or 0 and max_horizontal_speed_default.
# 
# ---  ---
# 
# - Put together some illustrative screenshots with special one-off annotations to explain the
#   graph parsing steps.
#   - A couple surfaces
#   - Show different tiles, to illustrate how surfaces get merged.
#   - All surfaces (different colors)
#   - A couple edges
#   - All edges
#   - 
# 
# - Update README.
# 
# ---  ---
# 
# - Add squirrel assets and animation.
#   - Start by copying-over the Piskel squirrel animation art.
#   - Create squirrel parts art in Aseprite.
#   - Create squirrel animation key frames in Godot.
#     - Idle, standing
#     - Idle, climbing
#     - Crawl-walk-sniff
#     - Bounding walk
#     - Climbing up
#     - Climbing down (just run climbing-up in reverse? Probably want to bound down, facing down,
#       as opposed to cat. Will make transition weird, but whatever?)
#     - 
# 
# ---  ---
# 
# - Loading screen
#   - While downloading, and while parsing level graph
#   - Hand-animated pixel art
#   - Simple GIF file
#   - Host/load/show separately from the rest of the JavaScript and assets
#   - Squirrels digging-up/eating tulips
# 
# - Welcome screen
#   - Hand-animated pixel art
#   x- Gratuitous whooshy sliding shine and a sparkle at the end
#   x- With squirrels running and climbing over the letters?
#   >- Approach:
#     - Start simple. Pick font. Render in Inkscape. Create a hand-pixel-drawn copy in Aseprite.
#     - V1: Show "Squirrel Away" text. Animate squirrel running across, right to left, in front of letters.
#     - V2: Have squirrel pause to the left of the S, with its tail overlapping the S. Give a couple tail twitches. Then have squirrel leave.
#     
# --- Expected cut-off for demo date ---
# 
# - Add some extra improvements to check_frame_for_collision:
#   - [maybe?] Rather than just using closest_intersection_point, sort all intersection_points, and
#     try each of them in sequence when the first one fails	
#   - [easy to add, might be nice for future] If that also fails, use a completely separate new
#     cheap-and-dirty check-for-collision-in-frame method?	
#     - Check if intersection_points is not-empty.
#     - Sort them by closest in direction of motion (and ignoring behind points).
#     - Iterate through points, trying to get tile index by a slight nudge offset from each
#       intersection point in the direction of motion until one sticks.
#     - Choose surface side just from dominant motion component.
#   - Add a field on the collision class for the type of collision check used
#   - Add another field (or another option for the above field) to indicate that none of the
#     collision checks worked, and this collision is in an error state
#   - Use this error state to abort collision/step/edge calculations (rather than the current
#     approach of returning null, which is the same as with not detecting any collisions at all).
# 
# - Add better annotation selection.
#   - Add shorcuts for toggling debugging annotations
#     - Add support for triggering the calc-step annotations based on a shortcut.
#       - i
#       - also, require clicking on the start and end positions in order to select which edge to
#         debug
#         - Use this _in addition to_ the current top-level configuration for specifying which edge
#           to calculate?
#       - also, then only actually calculate the edge debug state when using this click-to-specify
#         debug mode
#     - also, add other shortcuts for toggling other annotations:
#       - whether all surfaces are highlighted
#       - whether the player's position+collision boundary are rendered
#       - whether the player's current surface is rendered
#       - whether all edges are rendered
#       - whether grid boundaries+indices are rendered
#     - create a collapsible dat.GUI-esque menu at the top-right that lists all the possible
#       annotation configuration options
#       - set up a nice API for creating these, setting values, listening for value changes, and
#         defining keyboard shortcuts.
#   - Use InputMap to programatically add keybindings.
#     - This should enable our framework to setup all the shortcuts it cares about, without
#       consumers needing to ever redeclare anything in their project settings.
#     - This should also enable better API design for configuring keybindings and menu items from
#       the same place.
#     - https://godot-es-docs.readthedocs.io/en/latest/classes/class_inputmap.html#class-inputmap
# 
# 
# 
# >- Commit message:
# 




func _init(params: MovementParams).("jump_from_platform", params) -> void:
    self.can_traverse_edge = true
    self.can_traverse_to_air = true
    self.can_traverse_from_air = false

func get_all_edges_from_surface(debug_state: Dictionary, space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, possible_surfaces: Array, a: Surface) -> Array:
    var jump_positions: Array
    var land_positions: Array
    var terminals: Array
    var instructions: MovementInstructions
    var edge: InterSurfaceEdge
    var edges := []
    var overall_calc_params: MovementCalcOverallParams
    
    # FIXME: B: REMOVE
    params.gravity_fast_fall *= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    params.gravity_slow_rise *= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    var constraint_offset = MovementCalcOverallParams.calculate_constraint_offset(params)
    
    for b in possible_surfaces:
        # This makes the assumption that traversing through any fall-through/walk-through surface
        # would be better handled by some other Movement type, so we don't handle those
        # cases here.
        
        if a == b:
            continue
        
        # FIXME: D:
        # - Do a cheap bounding-box distance check here, before calculating any possible jump/land
        #   points.
        # - Don't forget to also allow for fallable surfaces (more expensive).
        # - This is still cheaper than considering all 9 jump/land pair instructions, right?
        
        jump_positions = MovementUtils.get_all_jump_positions_from_surface( \
                params, a, b.vertices, b.bounding_box, b.side)
        land_positions = MovementUtils.get_all_jump_positions_from_surface( \
                params, b, a.vertices, a.bounding_box, a.side)
        
        for jump_position in jump_positions:
            for land_position in land_positions:
                ###################################################################################
                # Allow for debug mode to limit the scope of what's calculated.
                if debug_state.in_debug_mode and debug_state.limit_parsing_to_single_edge != null:
                    var debug_origin: Dictionary = debug_state.limit_parsing_to_single_edge.origin
                    var debug_destination: Dictionary = \
                            debug_state.limit_parsing_to_single_edge.destination
                    
                    if a.side != debug_origin.surface_side or \
                            b.side != debug_destination.surface_side or \
                            a.first_point != debug_origin.surface_start_vertex or \
                            a.last_point != debug_origin.surface_end_vertex or \
                            b.first_point != debug_destination.surface_start_vertex or \
                            b.last_point != debug_destination.surface_end_vertex:
                        # Ignore anything except the origin and destination surface that we're
                        # debugging.
                        continue
                    
                    # Calculate the expected jumping position for debugging.
                    var debug_jump_position: PositionAlongSurface
                    match debug_origin.near_far_close_position:
                        "near":
                            debug_jump_position = jump_positions[0]
                        "far":
                            assert(jump_positions.size() > 1)
                            debug_jump_position = jump_positions[1]
                        "close":
                            assert(jump_positions.size() > 2)
                            debug_jump_position = jump_positions[2]
                        _:
                            Utils.error()
                    
                    # Calculate the expected landing position for debugging.
                    var debug_land_position: PositionAlongSurface
                    match debug_destination.near_far_close_position:
                        "near":
                            debug_land_position = land_positions[0]
                        "far":
                            assert(land_positions.size() > 1)
                            debug_land_position = land_positions[1]
                        "close":
                            assert(land_positions.size() > 2)
                            debug_land_position = land_positions[2]
                        _:
                            Utils.error()
                    
                    if jump_position != debug_jump_position or \
                            land_position != debug_land_position:
                        # Ignore anything except the jump and land positions that we're debugging.
                        continue
                ###################################################################################
                
                terminals = MovementConstraintUtils.create_terminal_constraints(a, \
                        jump_position.target_point, b, land_position.target_point, params, \
                        true)
                if terminals.empty():
                    continue
                
                overall_calc_params = MovementCalcOverallParams.new(params, space_state, \
                        surface_parser, terminals[0], terminals[1])
                
                ###################################################################################
                # Record some extra debug state when we're limiting calculations to a single edge.
                if debug_state.in_debug_mode and debug_state.limit_parsing_to_single_edge != null:
                    overall_calc_params.in_debug_mode = true
                ###################################################################################
                
                instructions = calculate_jump_instructions(overall_calc_params)
                if instructions != null:
                    # Can reach land position from jump position.
                    edge = InterSurfaceEdge.new(jump_position, land_position, instructions)
                    edges.push_back(edge)
                    # For efficiency, only compute one edge per surface pair.
                    break
            
            if edge != null:
                # For efficiency, only compute one edge per surface pair.
                edge = null
                break
    
    # FIXME: B: REMOVE
    params.gravity_fast_fall /= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    params.gravity_slow_rise /= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    return edges

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, position_start: PositionAlongSurface, \
        position_end: Vector2) -> MovementInstructions:
    var constraint_offset := MovementCalcOverallParams.calculate_constraint_offset(params)
    
    var terminals := MovementConstraintUtils.create_terminal_constraints(position_start.surface, \
            position_start.target_point, null, position_end, params, true)
    if terminals.empty():
        null
    
    var overall_calc_params := MovementCalcOverallParams.new(params, space_state, surface_parser, \
            terminals[0], terminals[1])
    
    return calculate_jump_instructions(overall_calc_params)

# Calculates instructions that would move the player from the given start position to the given end
# position.
# 
# This considers interference from intermediate surfaces, and will only return instructions that
# would produce valid movement without intermediate collisions.
static func calculate_jump_instructions( \
        overall_calc_params: MovementCalcOverallParams) -> MovementInstructions:
    var calc_results := MovementStepUtils.calculate_steps_with_new_jump_height( \
            overall_calc_params, null, null)
    
    if calc_results == null:
        return null
    
    var instructions: MovementInstructions = \
            MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
                    overall_calc_params.origin_constraint.position, \
                    overall_calc_params.destination_constraint.position, calc_results, true, \
                    overall_calc_params.destination_constraint.surface.side)
    
    if Utils.IN_DEV_MODE:
        MovementInstructionsUtils.test_instructions(instructions, overall_calc_params, calc_results)
    
    return instructions
