extends Node

const SAVE_PATH = "user://save.json"
var highscore: int = 0

func save():
	var data = {"highscore": highscore}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data:
		highscore = data.get("highscore", 0)
