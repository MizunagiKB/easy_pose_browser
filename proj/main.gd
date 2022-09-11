extends Control


const DEFAULT_THUMB_W = 128
const DEFAULT_THUMB_H = 128

var ary_current_path: Array = [""]
var ary_thumb: Array = []

var node_tex_rect = load("res://custom_texture_rect.tscn")
var tex_fold = load("res://res/ui/icon/folder-solid_normal.svg")


class CThumbInfo:
    var name: String = ""
    var image: Image = null
    
    static func sort_asc(a, b) -> bool:
        if a.name < b.name:
            return true
        return false

    func _init(name: String, image: Image):
        self.name = name
        self.image = image

    func get_texture(thumb_w: int, thumb_h: int) -> ImageTexture:
        var img = Image.new()
        var tex = ImageTexture.new()
        
        img.copy_from(self.image)
        img.resize(thumb_w, thumb_h)
        tex.create_from_image(img)        

        return tex


func decode_png(stream: StreamPeerBuffer) -> Image:
    
    var buf: PoolByteArray = PoolByteArray()
    var size = (stream.get_size() - stream.get_position()) / 2

    for n in range(size):
        stream.get_u8()
        buf.push_back(stream.get_u8())

    var img: Image = Image.new()
    
    if img.load_png_from_buffer(buf) == OK:
        return img
    else:
        return null


func get_epp_thumb(dname: String, fname: String) -> Image:

    var fr: File = File.new()
    var stream: StreamPeerBuffer = StreamPeerBuffer.new()
    
    fr.open(PoolStringArray([dname, fname]).join("/"), File.READ)
    stream.put_data(fr.get_buffer(fr.get_len()))
    stream.seek(0)

    while stream.get_position() < stream.get_size():
        var v = stream.get_u8()
        var n = stream.get_position()

        if v == 0x01:
            var check_count = 0
            for check in [0x89, 0x01, 0x50, 0x01, 0x4E, 0x01, 0x47]:
                if check == stream.get_u8():
                    check_count += 1
            if check_count == 7:
                stream.seek(n - 1)
                return decode_png(stream)
            else:
                stream.seek(n)

    return null


func update_tree():

    var o_list = $hsplit/list
    var o_dir = Directory.new()

    var current_path = PoolStringArray(ary_current_path).join("/")

    if current_path == "":
        ary_current_path = [""]
        current_path = "/"

    while $hsplit/vbox/hbox.get_child_count():
        $hsplit/vbox/hbox.remove_child($hsplit/vbox/hbox.get_child(0))

    var en: int = ary_current_path.size() - 1

    for n in range(ary_current_path.size()):
        var name = ary_current_path[n]
        
        match n:
            0:
                var btn = DirectoryButton.new()
                btn.flat = true
                btn.focus_mode = Control.FOCUS_NONE
                btn.text = "/"
                btn.connect("move_directory", self, "_on_move_directory")
                for n_dir in range(n + 1):
                    btn.ary_directory.push_back(ary_current_path[n_dir])
                $hsplit/vbox/hbox.add_child(btn)
            1:
                var btn = DirectoryButton.new()
                btn.flat = true
                btn.focus_mode = Control.FOCUS_NONE
                btn.text = "{0}".format([name])
                btn.connect("move_directory", self, "_on_move_directory")
                for n_dir in range(n + 1):
                    btn.ary_directory.push_back(ary_current_path[n_dir])
                $hsplit/vbox/hbox.add_child(btn)
            _:
                var lbl = Label.new()
                lbl.text = "/"
                $hsplit/vbox/hbox.add_child(lbl)

                var btn = DirectoryButton.new()
                btn.flat = true
                btn.focus_mode = Control.FOCUS_NONE
                btn.text = "{0}".format([name])
                btn.connect("move_directory", self, "_on_move_directory")
                for n_dir in range(n + 1):
                    btn.ary_directory.push_back(ary_current_path[n_dir])
                $hsplit/vbox/hbox.add_child(btn)

    # print(current_path)
    o_dir.open(current_path)
    o_dir.list_dir_begin()

    o_list.clear()
    
    ary_thumb.clear()

    var ary_name: Array = []
    
    var name = o_dir.get_next()

    while name != "":
        if o_dir.current_is_dir():
            if name != ".":
                ary_name.push_back(name)
        else:
            if name.ends_with(".epp"):
                var im: Image = get_epp_thumb(current_path, name)
                if im != null:
                    ary_thumb.append(CThumbInfo.new(name, im))
        name = o_dir.get_next()

    o_dir.list_dir_end()

    ary_name.sort()
    for dir_name in ary_name:
        var item = o_list.add_item(dir_name, tex_fold)

    update_grid()


func update_scroll():

    var thumb_size = $pnl_menu/scr_thumb_size.value
    var columns = $hsplit/vbox/scroll.rect_size.x / (thumb_size + 3)
    
    $hsplit/vbox/scroll/grid.columns = columns
    $pnl_menu/lbl_thumb_size.text = "{0} x {1}".format([thumb_size, thumb_size])
    # print("column ", $hsplit/scroll.rect_size.x)


func update_grid():

    var o_grid = $hsplit/vbox/scroll/grid
    var thumb_size = $pnl_menu/scr_thumb_size.value

    while o_grid.get_child_count():
        o_grid.remove_child(o_grid.get_child(0))

    ary_thumb.sort_custom(CThumbInfo, "sort_asc")
    for o_thumb in ary_thumb:
        var tex_rect = node_tex_rect.instance()

        tex_rect.hint_tooltip = o_thumb.name
        tex_rect.texture = o_thumb.get_texture(thumb_size, thumb_size)
        tex_rect.label = o_thumb.name.rstrip(".epp")
        o_grid.add_child(tex_rect)


func _ready():

    var ary_args = {}

    for argument in OS.get_cmdline_args():
        if argument.find("=") > -1:
            var key_value = argument.split("=")
            ary_args[key_value[0].lstrip("--")] = key_value[1]
        else:
            ary_args[argument.lstrip("--")] = ""

    if "open" in ary_args:
        ary_current_path = ary_args["open"].split("/")

    update_tree()
    update_scroll()


func _on_move_directory(ary_directory):
    
    ary_current_path = ary_directory
    
    update_tree()
    update_scroll()


func _on_list_item_selected(index):

    var name: String = $hsplit/list.get_item_text(index)

    if name == "..":
        self.ary_current_path.pop_back()
    else:
        self.ary_current_path.push_back(name)

    update_tree()


func _on_scroll_resized():
    update_scroll()


func _on_scr_thumb_size_value_changed(value):

    update_scroll()
    update_grid()

