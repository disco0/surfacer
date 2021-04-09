class_name Surface
extends Reference

# Vertices are always specified in clockwise order.
var vertices: PoolVector2Array

var side := SurfaceSide.NONE

var tile_map: SurfacesTileMap

# Array<int>
var tile_map_indices: Array

var bounding_box: Rect2
# The combined bounding box for the overall collection of transitively connected surfaces.
var connected_region_bounding_box := Rect2(Vector2.INF, Vector2.INF)

var normal := Vector2.INF

var clockwise_convex_neighbor: Surface
var counter_clockwise_convex_neighbor: Surface
var clockwise_concave_neighbor: Surface
var counter_clockwise_concave_neighbor: Surface

var first_point: Vector2 setget ,_get_first_point
var last_point: Vector2 setget ,_get_last_point

var center: Vector2 setget ,_get_center

var clockwise_neighbor: Surface setget ,_get_clockwise_neighbor
var counter_clockwise_neighbor: Surface setget ,_get_counter_clockwise_neighbor

func _init( \
        vertices := [], \
        side := SurfaceSide.NONE, \
        tile_map = null, \
        tile_map_indices := []) -> void:
    self.vertices = PoolVector2Array(vertices)
    self.side = side
    self.tile_map = tile_map
    self.tile_map_indices = tile_map_indices
    if !vertices.empty():
        self.bounding_box = Gs.geometry.get_bounding_box_for_points(vertices)
    if side != SurfaceSide.NONE:
        self.normal = SurfaceSide.get_normal(side)

func to_string() -> String:
    return "Surface{ %s, [ %s, %s ] }" % [ \
            SurfaceSide.get_string(side), \
            vertices[0], \
            vertices[vertices.size() - 1], \
        ]

func _get_first_point() -> Vector2:
    return vertices[0]

func _get_last_point() -> Vector2:
    return vertices[vertices.size() - 1]

func _get_center() -> Vector2:
    return bounding_box.position + (bounding_box.end - bounding_box.position) / 2.0

func _get_clockwise_neighbor() -> Surface:
    return clockwise_convex_neighbor if \
            clockwise_convex_neighbor != null else \
            clockwise_concave_neighbor

func _get_counter_clockwise_neighbor() -> Surface:
    return counter_clockwise_convex_neighbor if \
            counter_clockwise_convex_neighbor != null else \
            counter_clockwise_concave_neighbor

func load_from_json_object( \
        json_object: Dictionary, \
        context: Dictionary) -> void:
    vertices = PoolVector2Array(Gs.utils.from_json_object(json_object.v))
    side = json_object.s
    tile_map = context.id_to_tile_map[json_object.t]
    tile_map_indices = json_object.i
    bounding_box = Gs.geometry.get_bounding_box_for_points(vertices)
    normal = SurfaceSide.get_normal(side)
    connected_region_bounding_box = Gs.utils.from_json_object(json_object.crbb)
    clockwise_convex_neighbor = context.id_to_surface[json_object.cwv]
    counter_clockwise_convex_neighbor = context.id_to_surface[json_object.ccwv]
    clockwise_concave_neighbor = context.id_to_surface[json_object.cwc]
    counter_clockwise_concave_neighbor = \
            context.id_to_surface[json_object.ccwc]

func to_json_object() -> Dictionary:
    return {
        v = Gs.utils.to_json_object(vertices),
        s = side,
        t = tile_map.id,
        i = Gs.utils.to_json_object(tile_map_indices),
        crbb = Gs.utils.to_json_object(connected_region_bounding_box),
        cwv = clockwise_convex_neighbor.get_instance_id(),
        ccwv = counter_clockwise_convex_neighbor.get_instance_id(),
        cwc = clockwise_concave_neighbor.get_instance_id(),
        ccwc = counter_clockwise_concave_neighbor.get_instance_id(),
    }
