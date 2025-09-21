class_name EvolutionSidebar
extends PanelContainer

# Collapsible sidebar for evolution UI
# Provides sections: Run, Settings, Progress, Selection

signal section_toggled(name: String, visible: bool)

var sidebar_vbox: VBoxContainer

func _ready():
	# Fill entire right edge by default; parent can override anchors
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = -340
	offset_right = -10
	offset_top = 10
	offset_bottom = -10

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	sidebar_vbox = VBoxContainer.new()
	sidebar_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(sidebar_vbox)

	# Build default sections; content may be filled by owner later
	_add_section("Run")
	_add_section("Settings")
	_add_section("Progress")
	_add_section("Selection")

func _make_collapsible_section(title: String) -> Dictionary:
	var section := VBoxContainer.new()
	section.custom_minimum_size.x = 300
	section.add_theme_constant_override("separation", 6)
	var header := Button.new()
	header.text = "▼ " + title
	header.flat = true
	header.focus_mode = Control.FOCUS_NONE
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 300
	content.visible = true
	header.pressed.connect(func():
		content.visible = not content.visible
		header.text = ("▼ " if content.visible else "▶ ") + title
		emit_signal("section_toggled", title, content.visible)
	)
	section.add_child(header)
	section.add_child(content)
	return {"root": section, "header": header, "content": content}

func _add_section(title: String) -> void:
	var sec := _make_collapsible_section(title)
	sidebar_vbox.add_child(sec["root"])
	# Minimal placeholder
	var lbl := Label.new()
	lbl.text = title + " content"
	(sec["content"] as VBoxContainer).add_child(lbl)

func set_section_content(title: String, node: Control) -> void:
	# Replace placeholder content for a named section
	for s in sidebar_vbox.get_children():
		if s is VBoxContainer and s.get_child_count() >= 2:
			var header_btn := s.get_child(0)
			if header_btn is Button and (header_btn as Button).text.ends_with(title):
				var content_v := s.get_child(1)
				if content_v is VBoxContainer:
					for c in content_v.get_children():
						c.queue_free()
					content_v.add_child(node)
					return
