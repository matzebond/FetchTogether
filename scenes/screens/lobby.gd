extends Control

const url = "maschm.de"


onready var panelConnect = $Connect
onready var panelPlayers = $Players

onready var inputName = $Connect/VBoxContainer/Name
onready var lblError = $Connect/VBoxContainer/ErrorLabel

onready var btnPlayOnline = $Connect/VBoxContainer/BtnPlayOnline
onready var btnHostOffline = $Connect/VBoxContainer/HBoxContainer/BtnHostOffline
onready var btnPlayOffline = $Connect/VBoxContainer/HBoxContainer/BtnPlayOffline
onready var btnStart = $Players/Start

onready var listPlayers = $Players/List

func _ready():
    OS.center_window()
    
    # Called every time the node is added to the scene.
    State.connect("connection_failed", self, "_on_connection_failed")
    State.connect("connection_succeeded", self, "_on_connection_success")
    State.connect("player_list_changed", self, "refresh_lobby")
    State.connect("game_ended", self, "_on_game_ended")
    State.connect("game_error", self, "_on_game_error")
    
    # server down or network dead
    if not IP.resolve_hostname(url, 1):
        btnPlayOnline.disabled = true
    
    if OS.get_name() == "HTML5": # I think Web is not happy when failing
        btnHostOffline.disabled = true
        btnPlayOffline.disabled = true
    
    # Set the player name according to the system username. Fallback to the path.
    if OS.has_environment("USERNAME"):
        inputName.text = OS.get_environment("USERNAME")
    else:
        var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
        inputName.text = desktop_path[desktop_path.size() - 2]


func _on_host_pressed():
    if inputName.text == "":
        lblError.text = "Invalid name!"
        return

    panelConnect.hide()
    panelPlayers.show()
    lblError.text = ""

    var player_name = inputName.text
    State.host_game(player_name)
    refresh_lobby()


func _on_join_pressed(ip = null):
    if inputName.text == "":
        lblError.text = "Invalid name!"
        return

    lblError.text = ""
    btnPlayOffline.disabled = true
    btnPlayOnline.disabled = true
    btnHostOffline.disabled = true

    var player_name = inputName.text
    State.join_game(ip, player_name) # ip only set when hosting locally


func _on_connection_success():
    panelConnect.hide()
    panelPlayers.show()
    refresh_lobby()


func _on_connection_failed():
    btnPlayOffline.disabled = false
    btnPlayOnline.disabled = false
    btnHostOffline.disabled = false
    lblError.set_text("Connection failed.")


func _on_game_ended():
    show()
    panelConnect.show()
    panelPlayers.hide()
    btnPlayOffline.disabled = false
    btnPlayOnline.disabled = false
    btnHostOffline.disabled = false
    

func _on_game_error(errtxt):
    print(errtxt)
    $ErrorDialog.dialog_text = errtxt
    $ErrorDialog.popup_centered_minsize()
    btnPlayOffline.disabled = false
    btnPlayOnline.disabled = false
    btnHostOffline.disabled = false

func refresh_lobby():
    var players = State.get_player_list()
    players.sort()
    listPlayers.clear()
    listPlayers.add_item(State.get_player_name() + " (You)")
    for p in players:
        listPlayers.add_item(p)

    if State.can_start_game():
        btnStart.disabled = false
        btnStart.text = "Start"
    else:
        btnStart.disabled = true
        btnStart.text = "Waiting..."

func _on_start_pressed():
    State.begin_game()
