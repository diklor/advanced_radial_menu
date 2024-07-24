@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type('RadialMenuAdvanced', 'Control', preload('radial_menu_class.gd'), preload('icon.svg'))


func _exit_tree():
	remove_custom_type("RadialMenuAdvanced")
