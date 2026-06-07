extends Node

const SAVE_PATH = "user://leaderboard.json"
var scores: Array = []

func add_score(value: int) -> void:
	scores.append(value)
	scores.sort_custom(self._sort_scores)
	if scores.size() > 10:
		scores.resize(10)
	save()

func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data and typeof(data.result) == TYPE_DICTIONARY:
		scores = data.result.get("scores", [])

func save() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"scores": scores}))

func _sort_scores(a, b):
	return int(b) - int(a)
