extends TextureRect
class_name CustomTextureRect


var label: String setget set_label


func set_label(label: String):
    $pnl/lbl_name.text = label


func get_label() -> String:
    return $pnl/lbl_name.text

