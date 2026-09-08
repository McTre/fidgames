extends Node2D
## Shared interface. Games only receive normalized device input and game time.

signal haptic(event: String)

var device_locked := false
var show_grid := false

func advance(_delta: float, _input: Dictionary) -> void:
	pass

func save_state() -> Dictionary:
	return {}

func restore_state(_state: Dictionary) -> bool:
	return false

func diagnostics() -> String:
	return ""
