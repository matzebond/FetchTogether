extends Control

func _ready():
    # Called every time the node is added to the scene.
    State.connect("connection_failed", self, "_on_connection_failed")
    State.connect("connection_succeeded", self, "_on_connection_success")
    State.connect("player_list_changed", self, "refresh_lobby")
    State.connect("game_ended", self, "_on_game_ended")
    State.connect("game_error", self, "_on_game_error")
    # Set the player name according to the system username. Fallback to the path.
    if OS.has_environment("USERNAME"):
        $Connect/Name.text = OS.get_environment("USERNAME")
    else:
        var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
        $Connect/Name.text = desktop_path[desktop_path.size() - 2]


func _on_host_pressed():
    if $Connect/Name.text == "":
        $Connect/ErrorLabel.text = "Invalid name!"
        return

    $Connect.hide()
    $Players.show()
    $Connect/ErrorLabel.text = ""

    var player_name = $Connect/Name.text
    State.host_game(player_name)
    refresh_lobby()


func _on_join_pressed():
    if $Connect/Name.text == "":
        $Connect/ErrorLabel.text = "Invalid name!"
        return

    var ip = $Connect/IPAddress.text
    if not ip.is_valid_ip_address():
        $Connect/ErrorLabel.text = "Invalid IP address!"
        return

    $Connect/ErrorLabel.text = ""
    $Connect/Host.disabled = true
    $Connect/Join.disabled = true

    var player_name = $Connect/Name.text
    State.join_game(ip, player_name)


func _on_connection_success():
    $Connect.hide()
    $Players.show()


func _on_connection_failed():
    $Connect/Host.disabled = false
    $Connect/Join.disabled = false
    $Connect/ErrorLabel.set_text("Connection failed.")


func _on_game_ended():
    show()
    $Connect.show()
    $Players.hide()
    $Connect/Host.disabled = false
    $Connect/Join.disabled = false


func _on_game_error(errtxt):
    $ErrorDialog.dialog_text = errtxt
    $ErrorDialog.popup_centered_minsize()
    $Connect/Host.disabled = false
    $Connect/Join.disabled = false


func refresh_lobby():
    var players = State.get_player_list()
    players.sort()
    $Players/List.clear()
    $Players/List.add_item(State.get_player_name() + " (You)")
    for p in players:
        $Players/List.add_item(p)

    $Players/Start.disabled = not get_tree().is_network_server()


func _on_start_pressed():
    State.begin_game()


func _on_find_public_ip_pressed():
    OS.shell_open("https://icanhazip.com/")
