class_name SurfacerBootstrap
extends ScaffolderBootstrap

func _amend_app_manifest() -> void:
    ._amend_app_manifest()
    Surfacer.amend_app_manifest(app_manifest)

func _register_app_manifest() -> void:
    ._register_app_manifest()
    Surfacer.register_app_manifest(app_manifest)

func _initialize_framework() -> void:
    ._initialize_framework()
    Surfacer.initialize()
    
    _register_player_actions(Surfacer.player_action_classes)
    _register_edge_movements(Surfacer.edge_movement_classes)
    _register_player_params(Surfacer.player_param_classes)

func _on_app_initialized() -> void:
    ._on_app_initialized()
    Surfacer.annotators._on_app_initialized()
    
    Gs.audio.connect("beat", self, "_on_beat")

func _on_splash_finished() -> void:
    if !Surfacer.is_precomputing_platform_graphs:
        ._on_splash_finished()
    else:
        Gs.nav.open("precompute_platform_graphs")

func _register_player_actions(player_action_classes: Array) -> void:
    # Instantiate the various PlayerActions.
    for player_action_class in player_action_classes:
        Surfacer.player_actions[player_action_class.NAME] = \
                player_action_class.new()

func _register_edge_movements(edge_movement_classes: Array) -> void:
    # Instantiate the various EdgeMovements.
    for edge_movement_class in edge_movement_classes:
        Surfacer.edge_movements[edge_movement_class.NAME] = \
                edge_movement_class.new()

func _register_player_params(player_param_classes: Array) -> void:
    for param_class in player_param_classes:
        var player_params: PlayerParams = \
                PlayerParamsUtils.create_player_params(param_class)
        Surfacer.player_params[player_params.name] = player_params

func _on_beat(
        is_downbeat: bool,
        beat_index: int,
        meter: int) -> void:
    if Surfacer.is_metronome_enabled:
        var sound_name := \
                "tock_high" if \
                is_downbeat else \
                "tock_low"
        Gs.audio.play_sound(sound_name)
