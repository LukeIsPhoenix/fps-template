extends Control

@onready var player = get_tree().get_first_node_in_group("player")
@onready var fov_slider = $PanelContainer/VBoxContainer/HSlider
@onready var fov_label = $PanelContainer/VBoxContainer/fov_label

# Called when the node enters the scene tree for the first time.
func _ready():
	if player:
		fov_slider.value = player.FOV

	fov_slider.value_changed.connect(_on_fov_value_changed)
	fov_label.text = "FOV: %1.0f" % fov_slider.value

func _on_fov_value_changed(new_value: float):
	if player:
		player.FOV = new_value
	fov_label.text = "FOV: %1.0f" % fov_slider.value
