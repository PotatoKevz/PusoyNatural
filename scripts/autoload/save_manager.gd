extends Node

# Handles saving and loading

func save_data():
	var save_dict = {
		"money": GameManager.current_money,
		"wins": GameManager.total_wins,
		"losses": GameManager.total_losses,
		"sound": GameManager.sound_enabled,
		"music": GameManager.music_enabled
	}
	var save_file = FileAccess.open(GameManager.SAVE_FILE, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_dict))
		save_file.close()

func load_data():
	if not FileAccess.file_exists(GameManager.SAVE_FILE):
		return # No save file, use defaults
		
	var save_file = FileAccess.open(GameManager.SAVE_FILE, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.get_data()
			if data.has("money"): GameManager.current_money = data["money"]
			if data.has("wins"): GameManager.total_wins = data["wins"]
			if data.has("losses"): GameManager.total_losses = data["losses"]
			if data.has("sound"): GameManager.sound_enabled = data["sound"]
			if data.has("music"): GameManager.music_enabled = data["music"]
		save_file.close()
