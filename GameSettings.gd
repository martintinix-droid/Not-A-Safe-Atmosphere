extends Node
## Session settings that survive scene reloads (including Play Again).

const AVAILABLE_DURATIONS_MINUTES := [15, 20, 25, 30, 35, 40]

## Keep the previous choice selected when the duration screen opens again.
var selected_duration_seconds: int = 15 * 60

## Prevent the onboarding tutorial from appearing again after it is completed or skipped.
var tutorial_completed: bool = false

## The first tutorial completion reloads the scene to clear practice buildings.
## Skip the duration screen for that internal reload; Play Again still shows it.
var skip_duration_selection_once: bool = false


func set_duration_seconds(seconds: int) -> bool:
	var minutes := int(seconds / 60)
	if not AVAILABLE_DURATIONS_MINUTES.has(minutes) or minutes * 60 != seconds:
		return false
	selected_duration_seconds = seconds
	return true


func consume_skip_duration_selection_once() -> bool:
	var should_skip := skip_duration_selection_once
	skip_duration_selection_once = false
	return should_skip
