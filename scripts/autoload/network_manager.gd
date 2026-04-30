extends Node

# F-005: MockNetworkManager
# In Phase 1, all send_* methods return {ok: true, msg_id: <uuid>, mock: true}
# and print "[NETMOCK] <message_type> <payload_summary>".
# The real ENet-backed N-006 swap will preserve the same return shape so
# call sites do not branch.

# --- Message type constants (spec Part 18) ---
# Client -> Server
const MSG_CLICK_MOVE := "CLICK_MOVE"
const MSG_ATTACK_TARGET := "ATTACK_TARGET"
const MSG_BLOCK_START := "BLOCK_START"
const MSG_BLOCK_END := "BLOCK_END"
const MSG_DODGE := "DODGE"
const MSG_KICK := "KICK"
const MSG_INTERACT := "INTERACT"
const MSG_BUILD_PLACE := "BUILD_PLACE"
const MSG_BUILD_CONTRIBUTE := "BUILD_CONTRIBUTE"
const MSG_TRADE_OFFER := "TRADE_OFFER"
const MSG_MARKETPLACE_LIST := "MARKETPLACE_LIST"
const MSG_MARKETPLACE_BUY := "MARKETPLACE_BUY"
const MSG_CHAT := "CHAT"
const MSG_CRAFT := "CRAFT"
const MSG_EQUIP := "EQUIP"
const MSG_USE_ITEM := "USE_ITEM"
const MSG_GATHER := "GATHER"
const MSG_REVIVE := "REVIVE"
const MSG_EXECUTE := "EXECUTE"
const MSG_ZONE_TRAVEL := "ZONE_TRAVEL"
const MSG_AUTH_EMAIL := "AUTH_EMAIL"
const MSG_AUTH_WALLET := "AUTH_WALLET"

var is_local_mode: bool = true
var is_connected: bool = false
var server_tick: int = 0
var jwt_token: String = ""

signal connected_to_server()
signal disconnected_from_server()
signal auth_result(success: bool, character_data: Dictionary)


func _make_response(msg_type: String, payload: Dictionary = {}) -> Dictionary:
	var msg_id: String = "%d-%d" % [Time.get_ticks_msec(), randi()]
	if is_local_mode:
		print_rich("[color=cyan][NETMOCK][/color] %s %s" % [msg_type, str(payload)])
	return {"ok": true, "msg_id": msg_id, "mock": is_local_mode}


# --- Send helpers (call sites use these; mock returns immediately) ---

func send_move(target_pos: Vector3) -> Dictionary:
	return _make_response(MSG_CLICK_MOVE, {"tick": server_tick, "pos": [target_pos.x, target_pos.y, target_pos.z]})


func send_attack(target_id: int, tier: int, direction: int) -> Dictionary:
	return _make_response(MSG_ATTACK_TARGET, {"tick": server_tick, "target": target_id, "tier": tier, "dir": direction})


func send_block_start(direction: int) -> Dictionary:
	return _make_response(MSG_BLOCK_START, {"tick": server_tick, "dir": direction})


func send_block_end() -> Dictionary:
	return _make_response(MSG_BLOCK_END, {"tick": server_tick})


func send_dodge(direction: Vector2) -> Dictionary:
	return _make_response(MSG_DODGE, {"tick": server_tick, "dir": [direction.x, direction.y]})


func send_kick() -> Dictionary:
	return _make_response(MSG_KICK, {"tick": server_tick})


func send_interact(target_id: int, action: String) -> Dictionary:
	return _make_response(MSG_INTERACT, {"target": target_id, "action": action})


func send_build_place(structure_type: String, pos: Vector3, rotation: float) -> Dictionary:
	return _make_response(MSG_BUILD_PLACE, {"type": structure_type, "pos": [pos.x, pos.y, pos.z], "rot": rotation})


func send_build_contribute(structure_id: int, item_ids: Array) -> Dictionary:
	return _make_response(MSG_BUILD_CONTRIBUTE, {"structure": structure_id, "items": item_ids})


func send_trade_offer(target_player: int, offered_items: Array, requested_lamports: int) -> Dictionary:
	return _make_response(MSG_TRADE_OFFER, {"target": target_player, "items": offered_items, "lamports": requested_lamports})


func send_marketplace_list(item_id: int, price_lamports: int, quantity: int) -> Dictionary:
	return _make_response(MSG_MARKETPLACE_LIST, {"item": item_id, "price": price_lamports, "qty": quantity})


func send_marketplace_buy(listing_id: int, quantity: int) -> Dictionary:
	return _make_response(MSG_MARKETPLACE_BUY, {"listing": listing_id, "qty": quantity})


func send_chat(channel: String, message: String) -> Dictionary:
	return _make_response(MSG_CHAT, {"channel": channel, "msg": message})


func send_craft(recipe_id: String, station_id: int) -> Dictionary:
	return _make_response(MSG_CRAFT, {"recipe": recipe_id, "station": station_id})


func send_equip(item_id: int, slot: String) -> Dictionary:
	return _make_response(MSG_EQUIP, {"item": item_id, "slot": slot})


func send_use_item(item_id: int, target = null) -> Dictionary:
	return _make_response(MSG_USE_ITEM, {"item": item_id, "target": target})


func send_gather(node_id: int) -> Dictionary:
	return _make_response(MSG_GATHER, {"node": node_id})


func send_revive(target_character_id: int) -> Dictionary:
	return _make_response(MSG_REVIVE, {"target": target_character_id})


func send_execute(target_character_id: int) -> Dictionary:
	return _make_response(MSG_EXECUTE, {"target": target_character_id})


func send_zone_travel(target_zone_id: int) -> Dictionary:
	return _make_response(MSG_ZONE_TRAVEL, {"zone": target_zone_id})


func authenticate_email(email: String, _password: String) -> Dictionary:
	# Password not logged in mock for safety
	return _make_response(MSG_AUTH_EMAIL, {"email": email})


func authenticate_wallet(wallet_address: String, signature: String, message: String) -> Dictionary:
	return _make_response(MSG_AUTH_WALLET, {"wallet": wallet_address, "sig_len": signature.length(), "msg": message})


# Real-impl placeholder; N-006 swaps this in.
func connect_to_server() -> void:
	if is_local_mode:
		GameManager.log("info", "NetworkManager in local mode; connect_to_server() is a no-op")
		is_connected = true
		connected_to_server.emit()
