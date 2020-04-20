class_name SurfaceSide

enum {
    NONE,
    FLOOR,
    CEILING,
    LEFT_WALL,
    RIGHT_WALL,
}

static func get_side_string(side: int) -> String:
    match side:
        NONE:
            return "NONE"
        FLOOR:
            return "FLOOR"
        CEILING:
            return "CEILING"
        LEFT_WALL:
            return "LEFT_WALL"
        RIGHT_WALL:
            return "RIGHT_WALL"
        _:
            return "???"

static func get_normal(side: int) -> Vector2:
    return \
            Geometry.UP if side == FLOOR else (\
            Geometry.DOWN if side == CEILING else (\
            Geometry.RIGHT if side == LEFT_WALL else (\
            Geometry.LEFT)))
