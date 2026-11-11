extends SceneTree
func _initialize() -> void:
	var catalog=load("res://scripts/attack_catalog.gd").new()
	if not catalog.reload():
		push_error(catalog.error);quit(1);return
	var input:=FileAccess.open("res://data/attacks.csv",FileAccess.READ)
	var rows:Array[PackedStringArray]=[]
	var header:=input.get_csv_line()
	rows.append(header)
	var score_column:=header.find("score")
	while not input.eof_reached():
		var cells:=input.get_csv_line()
		if cells.size()!=header.size():continue
		var result:Dictionary=catalog.score_attack(catalog.attack(cells[0]))
		cells[score_column]=str(result.score) if result.valid else ""
		rows.append(cells)
	input.close()
	var output:=FileAccess.open("res://data/attacks.csv",FileAccess.WRITE)
	for row in rows:output.store_csv_line(row)
	output.close()
	quit(0)
