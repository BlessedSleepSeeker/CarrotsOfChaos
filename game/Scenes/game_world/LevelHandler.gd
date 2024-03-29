class_name LevelHandler
extends Node2D

@export var levelsFolderPath: String = "res://scenes/game_world/devlevels/"

var potentialLevelArray: Array = []
var spawnPointPos: Array = []

var cur_level: TileMap = null

signal level_finished(_body: Node2D)
signal level_started

signal player_death(_body: Node2D)

@onready var goalTile: PackedScene = preload("res://scenes/game_world/TileSetScenes/Goal.tscn")
@onready var deathTile: PackedScene = preload("res://scenes/game_world/TileSetScenes/DeathZone.tscn")

func _ready():
	pass

func buildLevelPath(lvlDifficulty: int) -> String:
	return "%s%d/" % [levelsFolderPath, lvlDifficulty]

func selectRandomLevelInFolder(folderPath: String) -> String:
	var dir = DirAccess.open(folderPath)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		print_debug(file_name)
		if '.tscn.remap' in file_name:
			file_name = file_name.trim_suffix('.remap')
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				potentialLevelArray.append(file_name)
			file_name = dir.get_next()
			if '.tscn.remap' in file_name:
				file_name = file_name.trim_suffix('.remap')
	else:
		print("An error occurred when trying to access the path.")
	if potentialLevelArray.is_empty():
		return ""
	potentialLevelArray.shuffle()
	return "%s%s" % [folderPath, potentialLevelArray[0]]

func swapLevel(lvlDifficulty: int) -> void:
	unloadLevel()
	loadLevel(lvlDifficulty)

func unloadLevel() -> void:
	cur_level.queue_free()
	potentialLevelArray = []
	spawnPointPos = []

func loadLevel(lvlDifficulty: int) -> void:
	var levelScenePath = buildLevelPath(lvlDifficulty)
	var levelScene = selectRandomLevelInFolder(levelScenePath)
	print_debug(levelScene)
	var scene: PackedScene = load(levelScene)
	var instance: TileMap = scene.instantiate()
	add_child(instance)
	cur_level = instance
	cur_level.update_internals()
	addMetadataToLevel()
	level_started.emit()

func addMetadataToLevel() -> void:
	for child in cur_level.get_children():
		if child.has_signal("death_entered"):
			var instance = deathTile.instantiate()
			cur_level.add_child(instance)
			instance.position = child.position
			instance.death_entered.connect(_on_death_entered)
		if child.has_signal("goal_reached"):
			var instance = goalTile.instantiate()
			cur_level.add_child(instance)
			instance.position = child.position
			instance.goal_reached.connect(_on_goal_reached)

func getSpawnPoints() -> Array:
	for tile in cur_level.get_used_cells_by_id(1, -1, Vector2i(-1, -1), 0):
		spawnPointPos.append(to_global(cur_level.map_to_local(tile)))
	return spawnPointPos

func getRandomSpawnPoint() -> Vector2:
	spawnPointPos.shuffle()
	return spawnPointPos[0]

func _on_death_entered(_body: Node2D):
	if _body.has_method("death") and not (_body.state_machine.state.name == "Death" or _body.state_machine.state.name == "OutOfGame"):
		_body.last_spawnpoint = getRandomSpawnPoint()
		_body.death()


func _on_goal_reached(_body: Node2D):
	level_finished.emit(_body)
