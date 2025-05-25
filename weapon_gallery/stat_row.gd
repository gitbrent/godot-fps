extends HBoxContainer
class_name StatRow

@onready var stat_name_label: Label = $LabelStatName
@onready var stat_progress_bar: ProgressBar = $ProgressBarStat

func set_stat(name: String, value: float, max_value: float = 100.0):
	stat_name_label.text = name
	stat_progress_bar.max_value = max_value
	stat_progress_bar.value = value
