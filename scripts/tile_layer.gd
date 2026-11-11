extends Node2D
# Terrain renderer that divides a large room into reusable 32x32-tile chunks.
# Each Chunk is a Node2D with its own retained draw commands: Godot can reuse them until invalidated.
# Editing a cell marks affected chunks dirty; movement and entity rendering remain independent.
# The tile array is shared with the editor/World so the artwork reads the current terrain.
# Reading help: docs/CODE_GUIDE.md.

# Retained draw commands, partitioned into non-overlapping 32x32-cell chunks.

const Art := preload("res://scripts/art.gd")
const CHUNK_SIZE := 32

# One independently redrawn terrain region, sharing its tile data with the owning layer.
class Chunk extends Node2D:
	var tiles: Array
	var level_size: Vector2i
	var cells: Rect2i
	var draw_count := 0
	var environment := ""
	var cosmetic_data := {}

	# Draw this helper node from its owner data; it is presentation only.
	func _draw() -> void:
		draw_count += 1
		var document: Dictionary = cosmetic_data.duplicate()
		document.merge({"tiles":tiles,"w":level_size.x,"h":level_size.y,"environment":environment},true)
		Art.Scenery.draw_decorations(self,document,cells)
		Art.draw_tile_range(self, tiles, level_size.x, level_size.y,
			cells.position.x, cells.position.y, cells.end.x, cells.end.y, environment)

var environment := ""
var has_scenery := false
var tiles: Array = []
var level_size := Vector2i.ZERO
var chunk_grid := Vector2i.ZERO
var chunks: Array[Chunk] = []

# Replace old chunks and partition the shared terrain array into non-overlapping drawable regions.
func setup(level_tiles: Array, w: int, h: int, room_environment := "", room_data: Dictionary = {}) -> void:
	environment = room_environment
	has_scenery = environment != "" or Art.Scenery.theme_for(room_data) in Art.Scenery.EnvironmentArt.THEMES
	for chunk in chunks:
		remove_child(chunk)
		chunk.free()
	chunks.clear()
	tiles = level_tiles
	level_size = Vector2i(w, h)
	chunk_grid = Vector2i(ceili(w / float(CHUNK_SIZE)), ceili(h / float(CHUNK_SIZE)))
	for y in chunk_grid.y:
		for x in chunk_grid.x:
			var chunk := Chunk.new()
			chunk.cosmetic_data = room_data
			chunk.environment = environment
			chunk.tiles = tiles
			chunk.level_size = level_size
			var start := Vector2i(x, y) * CHUNK_SIZE
			chunk.cells = Rect2i(start, (start + Vector2i.ONE * CHUNK_SIZE).min(level_size) - start)
			chunks.append(chunk)
			add_child(chunk)

# Only this cell and its cardinal neighbours can change appearance. Decorations
# belong to their source cell even when drawn one tile above a chunk boundary.
# Return unique chunk coordinates for deterministic invalidation checks.
# Invalidate chunks whose edge/corner artwork depends on this edited cell, returning unique chunk indices.
func mark_cell_dirty(c: Vector2i) -> Array[Vector2i]:
	var marked: Array[Vector2i] = []
	if not Rect2i(Vector2i.ZERO, level_size).has_point(c):
		return marked
	var offsets := [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	if has_scenery:
		# Surface props read up to three cells above or below their source cell.
		for dy in range(-3, 4):
			for dx in range(-1, 2):
				if Vector2i(dx, dy) not in offsets: offsets.append(Vector2i(dx, dy))
	for offset in offsets:
		var cell: Vector2i = c + offset
		if not Rect2i(Vector2i.ZERO, level_size).has_point(cell):
			continue
		var index := Vector2i(cell.x / CHUNK_SIZE, cell.y / CHUNK_SIZE)
		if index not in marked:
			marked.append(index)
			chunks[index.y * chunk_grid.x + index.x].queue_redraw()
	return marked

# Cosmetic water/prop edits invalidate retained drawings without rebuilding collision data.
func refresh_cosmetics() -> void:
	for chunk in chunks:chunk.queue_redraw()
