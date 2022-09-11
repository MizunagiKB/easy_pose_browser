extends Button
class_name DirectoryButton


var ary_directory: Array = []


signal move_directory(ary_directory)


func _pressed():
    emit_signal("move_directory", ary_directory)
    
