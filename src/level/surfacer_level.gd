tool
class_name SurfacerLevel, \
"res://addons/scaffolder/assets/images/editor_icons/scaffolder_level.png"
extends ScaffolderLevel
## The main level class for Surfacer.[br]
## -   You should extend this with a sub-class for your specific game.[br]
## -   You should then attach your sub-class to each of your level scenes.[br]
## -   You should add a SurfacesTileMap child node to each of your level
##     scenes, in order to define the collidable surfaces in your level.[br]


var camera_pan_controller: CameraPanController
var intro_choreographer: Choreographer


func _init() -> void:
    var graph_parser := PlatformGraphParser.new()
    add_child(graph_parser)


func _load() -> void:
    ._load()
    
    Sc.gui.hud.create_inspector()
    
    Su.graph_parser.parse(
            Sc.level_session.id,
            Su.is_debug_only_platform_graph_state_included)


func _start() -> void:
    ._start()
    
    camera_pan_controller = CameraPanController.new()
    add_child(camera_pan_controller)
    
    _execute_intro_choreography()
    
    call_deferred("_initialize_annotators")


#func _on_started() -> void:
#    ._on_started()


#func _add_human_player() -> void:
#    ._add_human_player()


#func _add_computer_players() -> void:
#    ._add_computer_players()


func _destroy() -> void:
    Sc.annotators.on_level_destroyed()
    
    if is_instance_valid(camera_pan_controller):
        camera_pan_controller._destroy()
    
    ._destroy()


#func quit(
#        has_finished: bool,
#        immediately: bool) -> void:
#    .quit(has_finished, immediately)


#func _update_editor_configuration() -> void
#    ._update_editor_configuration()


func _on_initial_input() -> void:
    ._on_initial_input()

    if is_instance_valid(intro_choreographer):
        intro_choreographer.on_interaction()


#func pause() -> void:
#    .pause()


#func on_unpause() -> void:
#    .on_unpause()


# Execute any intro cut-scene or initial navigation.
func _execute_intro_choreography() -> void:
    intro_choreographer = \
            Sc.level_config.get_intro_choreographer(Sc.level.human_player)
    if is_instance_valid(intro_choreographer):
        intro_choreographer.connect(
                "finished", self, "_on_intro_choreography_finished")
        add_child(intro_choreographer)
        intro_choreographer.start()
    else:
        _on_intro_choreography_finished()


func _on_intro_choreography_finished() -> void:
    human_player._log(
            "Intro choreography finished: %8.3fs" % Sc.time.get_play_time(),
            PlayerLogType.CUSTOM)
    if is_instance_valid(intro_choreographer):
        intro_choreographer.queue_free()
        intro_choreographer = null
    _show_welcome_panel()


func _initialize_annotators() -> void:
    set_tile_map_visibility(false)
    Sc.annotators.on_level_ready()
    for group in [
            Sc.players.GROUP_NAME_HUMAN_PLAYERS,
            Sc.players.GROUP_NAME_COMPUTER_PLAYERS]:
        for player in Sc.utils.get_all_nodes_in_group(group):
            player._on_annotators_ready()


func set_tile_map_visibility(is_visible: bool) -> void:
    # TODO: Also show/hide background. Parallax doesn't extend from CanvasItem
    #       or have the `visible` field though.
#    var backgrounds := Sc.utils.get_children_by_type(
#            self,
#            ParallaxBackground)
    var foregrounds: Array = Sc.utils.get_children_by_type(
            self,
            TileMap)
    for node in foregrounds:
        node.visible = is_visible


func get_is_intro_choreography_running() -> bool:
    return intro_choreographer != null
