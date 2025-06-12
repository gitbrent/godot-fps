extends HBoxContainer
class_name StatRow

@onready var stat_name_label: Label = $LabelStatName
@onready var stat_progress_bar: ProgressBar = $ProgressBarStat

func set_stat(stat_name: String, stat_value: float, stat_max_value: float = 100.0):
	stat_name_label.text = stat_name
	stat_progress_bar.max_value = stat_max_value
	stat_progress_bar.value = stat_value
