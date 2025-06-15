# cover_point.gd
extends StaticBody3D
class_name CoverPoint

# An array to hold references to our Marker3D cover positions and their availability.
# This will be populated automatically in _ready().
var _cover_spots: Array[Dictionary] = []

# When true, this cover point cannot be used by enemies (e.g., destroyed, too dangerous)
@export var is_available_for_use: bool = true:
	set(value):
		is_available_for_use = value
		# Optional: Visually indicate availability in editor/game
		if is_available_for_use:
			#_cover_mesh.material_override.albedo_color = Color.GREEN # Example
			pass
		else:
			#_cover_mesh.material_override.albedo_color = Color.RED # Example
			pass

func _ready():
	# Populate _cover_spots with data from Marker3D children
	_initialize_cover_spots()
	
	# Optional: Hide the visual mesh if it's just for editor representation
	# if $CoverMesh:
	#    $CoverMesh.visible = false

func _initialize_cover_spots() -> void:
	_cover_spots.clear()
	
	for child in get_children():
		if child is Marker3D and child.name.begins_with("CoverPosition"):
			_cover_spots.append({
				"marker": child,
				"is_occupied": false,
				"occupying_enemy_id": null # Store a unique ID of the enemy occupying it
			})
	if _cover_spots.is_empty():
		printerr("Warning: No 'CoverPosition' Marker3D nodes found in CoverPoint: ", name)

# Public API for enemies to request a cover position
# Returns the global_transform of the reserved position, or null if no spots available
func request_cover_position(requester_id: String) -> Transform3D:
	if not is_available_for_use:
		return Transform3D() # Return an invalid transform if cover point is not available

	for spot in _cover_spots:
		if not spot.is_occupied:
			spot.is_occupied = true
			spot.occupying_enemy_id = requester_id
			print("CoverPoint '", name, "' spot occupied by enemy '", requester_id, "'")
			return spot.marker.global_transform
	
	print("CoverPoint '", name, "' has no available spots.")
	return Transform3D() # Return an invalid transform if no spots available

# Public API for enemies to release a cover position
func release_cover_position(requester_id: String) -> void:
	for spot in _cover_spots:
		if spot.occupying_enemy_id == requester_id:
			spot.is_occupied = false
			spot.occupying_enemy_id = null
			print("CoverPoint '", name, "' spot released by enemy '", requester_id, "'")
			return
	printerr("Enemy '", requester_id, "' tried to release a spot not occupied by it in CoverPoint '", name, "'")

# Check if any spots are available without reserving
func has_available_spot() -> bool:
	if not is_available_for_use:
		return false
	for spot in _cover_spots:
		if not spot.is_occupied:
			return true
	return false

# Get the nearest available spot to a given global position (useful for enemies deciding)
func get_nearest_available_spot_transform(query_position: Vector3) -> Transform3D:
	if not is_available_for_use:
		return Transform3D()

	var nearest_spot_transform = Transform3D()
	var shortest_distance = INF

	for spot in _cover_spots:
		if not spot.is_occupied:
			var dist = query_position.distance_to(spot.marker.global_position)
			if dist < shortest_distance:
				shortest_distance = dist
				nearest_spot_transform = spot.marker.global_transform
	return nearest_spot_transform

# Get the nearest available spot for an enemy and reserve it
func request_nearest_cover_position(requester_id: String, query_position: Vector3) -> Transform3D:
	if not is_available_for_use:
		return Transform3D()

	var best_spot: Dictionary = {}
	var shortest_distance = INF

	for spot in _cover_spots:
		if not spot.is_occupied:
			var dist = query_position.distance_to(spot.marker.global_position)
			if dist < shortest_distance:
				shortest_distance = dist
				best_spot = spot

	if best_spot.is_empty():
		print("CoverPoint '", name, "' has no available spots near '", query_position, "'.")
		return Transform3D()

	best_spot.is_occupied = true
	best_spot.occupying_enemy_id = requester_id
	print("CoverPoint '", name, "' nearest spot occupied by enemy '", requester_id, "'")
	return best_spot.marker.global_transform
