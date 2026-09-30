class_name GameUI
extends CanvasLayer
## Interface em português. Todos os controles visuais pertencem à cena game_ui.tscn.

signal action_requested(action_name: String, payload: String)

const PAPER := Color("edf0dc")
const MUTED := Color("b3c7c3")
const AMBER := Color("efbd70")
const NAMES := {"wood": "Madeira", "stone": "Pedra", "scrap": "Sucata", "part": "Peças", "food": "Comida"}
const STAGES := ["Reforçar a estrutura", "Restaurar o mecanismo", "Montar a lanterna"]

@onready var root: Control = $Root
@onready var hud: Control = $Root/HUD
@onready var modal: Control = $Root/Modal
@onready var shelter: PanelContainer = $Root/Shelter

@onready var life: ProgressBar = $Root/HUD/Status/Life
@onready var energy: ProgressBar = $Root/HUD/Status/Energy
@onready var life_label: Label = $Root/HUD/Status/LifeLabel
@onready var energy_label: Label = $Root/HUD/Status/EnergyLabel
@onready var clock_label: Label = $Root/HUD/Clock/ClockLabel
@onready var phase_label: Label = $Root/HUD/Clock/PhaseLabel
@onready var direction_label: Label = $Root/HUD/Clock/DirectionLabel
@onready var direction_arrow: Label = $Root/HUD/DirectionArrow
@onready var objective: Label = $Root/HUD/Objective
@onready var bag_label: Label = $Root/HUD/Inventory/BagLabel
@onready var bag_items: Label = $Root/HUD/Inventory/BagItems
@onready var resource_counts := {
	"wood": $Root/HUD/ResourceStrip/Wood/Count,
	"stone": $Root/HUD/ResourceStrip/Stone/Count,
	"scrap": $Root/HUD/ResourceStrip/Scrap/Count,
	"part": $Root/HUD/ResourceStrip/Part/Count,
	"food": $Root/HUD/ResourceStrip/Food/Count,
}
@onready var prompt: Label = $Root/HUD/Prompt
@onready var toast_label: Label = $Root/HUD/Toast
@onready var prompt_backdrop: Panel = $Root/HUD/PromptBackdrop
@onready var toast_backdrop: Panel = $Root/HUD/ToastBackdrop

@onready var modal_title: Label = $Root/Modal/Content/Title
@onready var modal_subtitle: Label = $Root/Modal/Content/Subtitle
@onready var modal_body: Label = $Root/Modal/Content/Body
@onready var modal_footer: Label = $Root/Modal/Content/Footer
@onready var modal_caption: Label = $Root/Modal/Caption
@onready var continue_button: Button = $Root/Modal/Content/Buttons/Continue
@onready var new_button: Button = $Root/Modal/Content/Buttons/New
@onready var confirm_new_button: Button = $Root/Modal/Content/Buttons/ConfirmNew
@onready var cancel_new_button: Button = $Root/Modal/Content/Buttons/CancelNew
@onready var begin_button: Button = $Root/Modal/Content/Buttons/Begin
@onready var resume_button: Button = $Root/Modal/Content/Buttons/Resume
@onready var silence_button: Button = $Root/Modal/Content/Buttons/Mute
@onready var menu_button: Button = $Root/Modal/Content/Buttons/Menu

@onready var stock_wood: Label = $Root/Shelter/Scroll/Column/Stock/Wood/Label
@onready var stock_stone: Label = $Root/Shelter/Scroll/Column/Stock/Stone/Label
@onready var stock_scrap: Label = $Root/Shelter/Scroll/Column/Stock/Scrap/Label
@onready var stock_part: Label = $Root/Shelter/Scroll/Column/Stock/Part/Label
@onready var stock_food: Label = $Root/Shelter/Scroll/Column/Stock/Food/Label
@onready var withdraw_wood: Button = $Root/Shelter/Scroll/Column/Stock/Wood/Withdraw
@onready var withdraw_stone: Button = $Root/Shelter/Scroll/Column/Stock/Stone/Withdraw
@onready var withdraw_scrap: Button = $Root/Shelter/Scroll/Column/Stock/Scrap/Withdraw
@onready var withdraw_part: Button = $Root/Shelter/Scroll/Column/Stock/Part/Withdraw
@onready var withdraw_food: Button = $Root/Shelter/Scroll/Column/Stock/Food/Withdraw
@onready var fire_label: Label = $Root/Shelter/Scroll/Column/FireLabel
@onready var repair_label: Label = $Root/Shelter/Scroll/Column/RepairLabel
@onready var repair_button: Button = $Root/Shelter/Scroll/Column/Repair
@onready var fuel_button: Button = $Root/Shelter/Scroll/Column/Fuel
@onready var ignite_button: Button = $Root/Shelter/Scroll/Column/Ignite
@onready var deposit_button: Button = $Root/Shelter/Scroll/Column/Deposit

var toast_timer := 0.0
var stock_labels := {}
var withdraw_buttons := {}
var muted := false


func _ready() -> void:
	stock_labels = {
		"wood": stock_wood,
		"stone": stock_stone,
		"scrap": stock_scrap,
		"part": stock_part,
		"food": stock_food,
	}
	withdraw_buttons = {
		"wood": withdraw_wood,
		"stone": withdraw_stone,
		"scrap": withdraw_scrap,
		"part": withdraw_part,
		"food": withdraw_food,
	}
	_connect_button(continue_button, "continue")
	_connect_button(new_button, "new")
	_connect_button(confirm_new_button, "confirm_new")
	_connect_button(cancel_new_button, "cancel_new")
	_connect_button(begin_button, "begin")
	_connect_button(resume_button, "resume")
	_connect_button(silence_button, "mute")
	_connect_button(menu_button, "menu")
	_connect_button($Root/Shelter/Scroll/Column/Heading/Close, "close_shelter")
	_connect_button(deposit_button, "deposit")
	_connect_button(withdraw_wood, "withdraw", "wood")
	_connect_button(withdraw_stone, "withdraw", "stone")
	_connect_button(withdraw_scrap, "withdraw", "scrap")
	_connect_button(withdraw_part, "withdraw", "part")
	_connect_button(withdraw_food, "withdraw", "food")
	_connect_button(fuel_button, "fuel")
	_connect_button(repair_button, "repair")
	_connect_button(ignite_button, "ignite")
	_hide_modal_buttons()
	shelter.hide()


func _connect_button(control: Button, command: String, payload: String = "") -> void:
	control.pressed.connect(func() -> void: action_requested.emit(command, payload))


func _hide_modal_buttons() -> void:
	for control: Button in [continue_button, new_button, confirm_new_button, cancel_new_button, begin_button, resume_button, silence_button, menu_button]:
		control.hide()


func _prepare_modal(title: String, subtitle: String, body: String = "", footer: String = "") -> void:
	_hide_modal_buttons()
	shelter.hide()
	modal_title.text = title
	modal_subtitle.text = subtitle
	modal_body.text = body
	modal_body.visible = not body.is_empty()
	modal_body.remove_theme_color_override("font_color")
	modal_footer.text = footer
	modal_footer.visible = not footer.is_empty()
	modal_caption.text = ""
	modal.show()


func clear_modal() -> void:
	modal.hide()


func show_menu(can_continue: bool, error: String = "") -> void:
	hud.hide()
	var footer := "Explore. Prepare o abrigo. Reconstrua o farol.\nWASD para mover · Mouse para mirar"
	if not error.is_empty():
		footer += "\n\n" + error
	_prepare_modal("O Farol", "A ilha guarda o passado.\nUma luz pode devolver seu futuro.", "", footer)
	continue_button.visible = can_continue
	new_button.show()
	silence_button.show()
	modal_caption.text = "Um protótipo de sobrevivência"
	(continue_button if can_continue else new_button).grab_focus()


func show_intro() -> void:
	hud.hide()
	_prepare_modal(
		"À deriva",
		"Na busca por sua família desaparecida, você encontrou uma ilha que não existe nos mapas. O naufrágio levou quase tudo. No alto da costa, um farol inacabado ainda oferece uma chance.",
		"A noite já tomou a ilha. Recolha madeira e pedra, guarde os materiais no depósito e procure sucata e peças nas ruínas distantes.\n\nAbasteça a fogueira assim que puder: a luz mantém os animais afastados até o amanhecer."
	)
	begin_button.show()
	begin_button.grab_focus()


func show_pause() -> void:
	_prepare_modal(
		"Maré suspensa",
		"Jogo pausado. Respire; a ilha pode esperar.",
		"",
		"O progresso é salvo ao amanhecer e após cada reparo. Voltar ao menu também guarda sua posição atual.\n\nWASD mover · Shift correr · Clique atacar\nE interagir · Q comer · Esc pausar"
	)
	resume_button.show()
	silence_button.show()
	menu_button.text = "Voltar ao menu"
	menu_button.show()
	resume_button.grab_focus()


func show_new_confirmation() -> void:
	hud.hide()
	_prepare_modal("Uma nova costa", "Começar novamente substitui a expedição salva neste computador.")
	confirm_new_button.show()
	cancel_new_button.show()
	cancel_new_button.grab_focus()


func show_victory(days: int) -> void:
	hud.hide()
	_prepare_modal(
		"Uma luz no horizonte",
		"O farol rompeu a escuridão. Um barco respondeu ao sinal. Você está voltando para casa.",
		"Resgate após %d dias na ilha" % days,
		"A história da sua família continua além desta costa.\nPor enquanto, você sobreviveu."
	)
	modal_body.add_theme_color_override("font_color", AMBER)
	menu_button.text = "Voltar ao início"
	menu_button.show()
	menu_button.grab_focus()


func show_play() -> void:
	clear_modal()
	hud.show()


func toggle_shelter() -> void:
	shelter.visible = not shelter.visible


func toast(message: String, duration: float = 4.0) -> void:
	toast_label.text = message
	toast_label.modulate.a = 1.0
	toast_backdrop.show()
	toast_timer = duration


func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		toast_label.modulate.a = minf(toast_timer, 1.0)
	else:
		toast_label.text = ""
		toast_label.modulate.a = 1.0
		toast_backdrop.hide()


func set_muted(value: bool) -> void:
	muted = value
	silence_button.text = "Som: desligado" if muted else "Som: ligado"


func set_lighthouse_direction(direction_to_lighthouse: Vector2) -> void:
	var direction := direction_to_lighthouse.normalized()
	if direction.is_zero_approx():
		direction = Vector2.UP
	# O glifo aponta para cima em rotação zero.
	direction_arrow.rotation = direction.angle() + PI / 2.0


func update_hud(state, distance: float, interaction: String, safe: bool) -> void:
	life.value = state.health
	energy.value = state.stamina
	life_label.text = "VIDA  %d" % ceili(state.health)
	energy_label.text = "ENERGIA  %d" % ceili(state.stamina)
	clock_label.text = "NOITE %d" % state.day if state.is_night() else "DIA %d" % state.day
	var remaining: int = ceili((360.0 if state.is_night() else 240.0) - state.time_of_day)
	phase_label.text = ("Amanhece em " if state.is_night() else "Anoitece em ") + "%02d:%02d" % [remaining / 60, remaining % 60]
	direction_label.text = "Abrigo protegido" if safe else "Farol · %d m" % int(distance / 10.0)
	if state.won:
		objective.text = "O farol está aceso · Resgate a caminho"
	elif state.repair_stage == 3:
		objective.text = "Acenda o farol para chamar o resgate"
	else:
		objective.text = "Farol %d/3 · %s" % [state.repair_stage, STAGES[state.repair_stage]]
	bag_label.text = "MOCHILA  %d / 20" % state.bag_count()
	bag_items.text = "Madeira %d  Pedra %d  Sucata %d\nPeças %d  Comida %d" % [state.bag.wood, state.bag.stone, state.bag.scrap, state.bag.part, state.bag.food]
	for kind: String in resource_counts:
		(resource_counts[kind] as Label).text = str(state.bag[kind])
	prompt.text = interaction if not shelter.visible else ""
	prompt_backdrop.visible = not prompt.text.is_empty()
	if shelter.visible:
		for kind: String in NAMES:
			stock_labels[kind].text = "%s    %d / %d" % [NAMES[kind], state.storage[kind], state.bag[kind]]
			withdraw_buttons[kind].disabled = state.storage[kind] <= 0 or state.bag_count() >= 20
		deposit_button.disabled = state.bag_count() == 0
		fire_label.text = "Fogueira · %ds de proteção noturna" % ceili(state.fuel)
		fuel_button.disabled = state.fuel >= 240 or state.bag.wood + state.storage.wood <= 0
		var cost: Dictionary = state.next_cost()
		var lines: PackedStringArray = []
		var can_repair := true
		for kind: String in cost:
			lines.append("%s %d/%d" % [NAMES[kind], state.storage[kind], cost[kind]])
			if state.storage[kind] < cost[kind]:
				can_repair = false
		repair_label.text = "Farol pronto. Acenda a luz quando quiser partir." if state.repair_stage == 3 else "%s\n%s" % [STAGES[state.repair_stage], " · ".join(lines)]
		repair_button.visible = state.repair_stage < 3
		repair_button.disabled = not can_repair
		ignite_button.visible = state.repair_stage == 3
