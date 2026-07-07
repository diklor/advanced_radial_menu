# advanced_radial_menu

Advanced radial menu node

![icon](https://f003.backblazeb2.com/file/ayanami/files/Lnc-JLcvf.jpg)

### Usage video
https://ayanami.app/_iwkUXrU6


## 1.4 Big rewrite!

### - !!! Changed: children are now located in clockwise order
- Changed: `animated_pulse_offset` parameter works the opposite way (more logically). Negative values are offsetting inside the circle
- Changed: Children rotation and scale are changed only once when:
- - Child added, removed or reordered
- - Radial menu visibility is changed (but you can use `radial_menu.force_update()`)
- - Changed one of the following parameters: `enabled`, `first_in_center`, `children_rotate` 
- Added new parameter `children_distance_offset` - offsets children from the center
- Added new parameter `children_rotate_inverted` - inverts children rotation (towards or away from center)
- Removed parameter `children_optimized`. Children collection is not happening on every frame and optimized by default
- Extremely optimized and more fast
- More of static typing

## 1.3 Update
* Temporary selections
* Signal docs
* .gdignore finally
* Controller support and mouse detection fixes



# Temporarily selection
Set
```gdscript
radial_menu.set_temporary_selection(1)
# (1 is second element, 0 is first)
```
Remove
```gdscript
radial_menu.set_temporary_selection(-2) # -2 is nothing
```
# Signals
Connect slot selection
```gdscript
# Example how to make selected slot green
var _prev_slot: Control = null

func _ready() -> void:
  radial_menu.slot_selected.connect(func(slot: Control, index: int) -> void:
    if _prev_slot != null:
      _prev_slot.modulate = Color.WHITE
    slot.modulate = Color.GREEN
    _prev_slot = slot
  )
```
Selection changed (hover):
```gdscript
radial_menu.selection_changed.connect(func(new_selection: int) -> void:
	var slot := radial_menu.get_selected_child()
)
# You can animate `slot.scale` because radial_menu is not a container
```
Selection canceled:
```gdscript
radial_menu.selection_canceled.connect(func() -> void: ...
```

---


# What the hell with indexes?
* -2 is nothing
* -1 is center slot (only if you have `first_in_center` variable enabled)
* 0 is first slot

It's just ordinary indexes, but -1 became -2

_If you work with a team, you should probably comment these incomprehensible -2 indexes in the code..._




What is **deadzone**?
# What is **deadzone**?

![deadzone.jpg](https://i.postimg.cc/QCgLZL9k/fcc4ae0b.jpg)

The threshold of detection. For example, in the picture of the deadzone is 0.2, means the values ​​below or equals 0.2 will be ignored


| [Download `example.tscn` (downgit)](https://downgit.github.io/#/home?url=https://github.com/diklor/advanced_radial_menu/blob/main/example.tscn) |
| - |

## Support

<a href="https://www.buymeacoffee.com/verdicted" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
