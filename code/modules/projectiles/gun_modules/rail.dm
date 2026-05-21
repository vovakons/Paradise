/obj/item/gun_module/rail
	slot = ATTACHMENT_SLOT_RAIL

/obj/item/gun_module/rail/scope
	/// 'zoom' distance
	var/zoom_amount = 1
	var/spread_decrease_mod = 0.50
	var/movespeed_slowdown = 1.5
	/// bonus accuracy for gun
	var/bonus_accuracy = 0
	var/old_zoom_amount
	var/spread_decrease
	var/movespeed_mod

/obj/item/gun_module/rail/scope/on_attach(obj/item/gun/target_gun, mob/user)
	target_gun.zoomable = TRUE
	old_zoom_amount = target_gun.zoom_amt
	target_gun.zoom_amt = zoom_amount
	target_gun.build_zooming()
	if(user && user.is_in_hands(target_gun))
		target_gun.ZoomGrantCheck(null, user, ITEM_SLOT_HANDS)
	RegisterSignal(target_gun, COMSIG_GUN_ZOOM_TOGGLE, PROC_REF(zoom_toogle))

/obj/item/gun_module/rail/scope/on_detach(obj/item/gun/target_gun, mob/user)
	target_gun.zoomable = FALSE
	target_gun.zoom_amt = old_zoom_amount
	target_gun.destroy_zooming()
	UnregisterSignal(target_gun, COMSIG_GUN_ZOOM_TOGGLE)

/obj/item/gun_module/rail/scope/proc/zoom_toogle(datum/source, mob/user)
	if(gun.zoomed)
		on_enter_sight_mode(user)
	else
		on_leave_sight(user)

/obj/item/gun_module/rail/scope/proc/on_enter_sight_mode(mob/user)
	gun.accuracy.add_accuracy(bonus_accuracy)
	spread_decrease = initial(gun.accuracy.max_spread) * spread_decrease_mod
	gun.accuracy.max_spread = max(gun.accuracy.max_spread - spread_decrease, 0)
	var/mob/living/carbon/human/human = user
	if(istype(human))
		movespeed_mod = new /datum/movespeed_modifier/sight_mode(slowdown = movespeed_slowdown)
		human.add_movespeed_modifier(movespeed_mod)

/obj/item/gun_module/rail/scope/proc/on_leave_sight(mob/user)
	gun.accuracy.add_accuracy(-bonus_accuracy)
	gun.accuracy.max_spread += spread_decrease
	spread_decrease = 0
	var/mob/living/carbon/human/human = user
	if(istype(human) && movespeed_mod)
		human.remove_movespeed_modifier(movespeed_mod)
		movespeed_mod = null

/**
 * MARK: Collimator Sight
 */

/obj/item/gun_module/rail/scope/collimator
	name = "collimator scope"
	desc = "Коллиматорный прицел, предназначенный для установки на прицельную планку стрелкового оружия. Несовместим с пистолетами. Повышает удобство и точность стрельбы."
	icon_state = "coll"
	item_state = "coll"
	overlay_state = "coll_o"
	overlay_offset = list("x" = -5, "y" = 0)
	class = GUN_MODULE_CLASS_SHOTGUN_RAIL | GUN_MODULE_CLASS_RIFLE_RAIL | GUN_MODULE_CLASS_SNIPER_RAIL
	zoom_amount = 3
	bonus_accuracy = 10
	spread_decrease_mod = 0.30
	movespeed_slowdown = 1.3
	custom_price = 1.5 * PAYCHECK_LOWER

/obj/item/gun_module/rail/scope/collimator/get_ru_names()
	return list(
		NOMINATIVE = "коллиматорный прицел",
		GENITIVE = "коллиматорного прицела",
		DATIVE = "коллиматорному прицелу",
		ACCUSATIVE = "коллиматорный прицел",
		INSTRUMENTAL = "коллиматорным прицелом",
		PREPOSITIONAL = "коллиматорном прицеле",
	)

/obj/item/gun_module/rail/scope/collimator/pistol
	name = "pistol collimator scope"
	desc = "Коллиматорный прицел, предназначенный для установки на прицельную планку пистолета. Повышает удобство и точность стрельбы."
	icon_state = "coll_p"
	item_state = "coll_p"
	overlay_state = "coll_p_o"
	class = GUN_MODULE_CLASS_PISTOL_RAIL
	custom_price = PAYCHECK_LOWER

/obj/item/gun_module/rail/scope/collimator/pistol/get_ru_names()
	return list(
		NOMINATIVE = "пистолетный коллиматорный прицел",
		GENITIVE = "пистолетного коллиматорного прицела",
		DATIVE = "пистолетному коллиматорному прицелу",
		ACCUSATIVE = "пистолетный коллиматорный прицел",
		INSTRUMENTAL = "пистолетным коллиматорным прицелом",
		PREPOSITIONAL = "пистолетном коллиматорном прицеле",
	)

/**
 * MARK: Optical Sight
 */

/obj/item/gun_module/rail/scope/x4
	name = "optical scope x4"
	desc = "Оптический прицел с 4-кратным увеличением, предназначенный для установки на прицельную планку стрелкового оружия. Повышает точность при стрельбе на дальние дистанции."
	icon_state = "x4"
	item_state = "x4"
	overlay_state = "x4_o"
	overlay_offset = list("x" = -5, "y" = 0)
	class = GUN_MODULE_CLASS_SHOTGUN_RAIL | GUN_MODULE_CLASS_RIFLE_RAIL | GUN_MODULE_CLASS_SNIPER_RAIL
	zoom_amount = 5
	bonus_accuracy = 10
	spread_decrease_mod = 0.40
	movespeed_slowdown = 1.6
	custom_price = 3 * PAYCHECK_MAX

/obj/item/gun_module/rail/scope/x4/get_ru_names()
	return list(
		NOMINATIVE = "оптический прицел х4",
		GENITIVE = "оптического прицела х4",
		DATIVE = "оптическому прицелу х4",
		ACCUSATIVE = "оптический прицел х4",
		INSTRUMENTAL = "оптическим прицелом х4",
		PREPOSITIONAL = "оптическом прицеле х4",
	)

/obj/item/gun_module/rail/scope/x8
	name = "optical scope x8"
	desc = "Оптический прицел с 8-кратным увеличением, предназначенный для установки на прицельную планку стрелкового оружия. Повышает точность при стрельбе на дальние дистанции."
	icon_state = "x8"
	item_state = "x8"
	overlay_state = "x8_o"
	overlay_offset = list("x" = -5, "y" = 0)
	class = GUN_MODULE_CLASS_RIFLE_RAIL | GUN_MODULE_CLASS_SNIPER_RAIL
	zoom_amount = 7
	bonus_accuracy = 30
	movespeed_slowdown = 2
	custom_price = 5 * PAYCHECK_MAX

/obj/item/gun_module/rail/scope/x8/get_ru_names()
	return list(
		NOMINATIVE = "оптический прицел х8",
		GENITIVE = "оптического прицела х8",
		DATIVE = "оптическому прицелу х8",
		ACCUSATIVE = "оптический прицел х8",
		INSTRUMENTAL = "оптическим прицелом х8",
		PREPOSITIONAL = "оптическом прицеле х8",
	)

/obj/item/gun_module/rail/scope/x16
	name = "optical scope x16"
	desc = "Оптический прицел с 16-кратным увеличением, предназначенный для установки на прицельную планку стрелкового оружия. Повышает точность при стрельбе на дальние дистанции."
	icon_state = "x16"
	item_state = "x16"
	overlay_state = "x16_o"
	overlay_offset = list("x" = -3, "y" = 0)
	class = GUN_MODULE_CLASS_RIFLE_RAIL | GUN_MODULE_CLASS_SNIPER_RAIL
	zoom_amount = 11
	bonus_accuracy = 50
	spread_decrease_mod = 0.75
	movespeed_slowdown = 2.5
	custom_price = 10 * PAYCHECK_MAX

/obj/item/gun_module/rail/scope/x16/get_ru_names()
	return list(
		NOMINATIVE = "оптический прицел х16",
		GENITIVE = "оптического прицела х16",
		DATIVE = "оптическому прицелу х16",
		ACCUSATIVE = "оптический прицел х16",
		INSTRUMENTAL = "оптическим прицелом х16",
		PREPOSITIONAL = "оптическом прицеле х16",
	)

/**
 * MARK: HUD Sight
 */

/obj/item/gun_module/rail/hud
	var/hud_type
	var/granted = FALSE

/obj/item/gun_module/rail/hud/on_attach(obj/item/gun/target_gun, mob/user)
	RegisterSignal(target_gun, COMSIG_ITEM_EQUIPPED, PROC_REF(equip_gun_check))
	RegisterSignal(target_gun, COMSIG_ITEM_DROPPED, PROC_REF(drop_gun_check))
	if(user.is_in_hands(target_gun))
		equip_gun_check(null, user, ITEM_SLOT_HANDS)

/obj/item/gun_module/rail/hud/on_detach(obj/item/gun/target_gun, mob/user)
	UnregisterSignal(target_gun, COMSIG_ITEM_EQUIPPED)
	UnregisterSignal(target_gun, COMSIG_ITEM_DROPPED)
	remove_hud(user)

/obj/item/gun_module/rail/hud/proc/equip_gun_check(datum/source, mob/user, slot)
	if(!(slot & ITEM_SLOT_HANDS))
		remove_hud(user)
		return
	grant_hud(user)

/obj/item/gun_module/rail/hud/proc/drop_gun_check(datum/source, mob/user)
	remove_hud(user)

/obj/item/gun_module/rail/hud/proc/grant_hud(mob/user)
	if(granted)
		return
	granted = TRUE
	if(islist(hud_type))
		for(var/new_hud in hud_type)
			var/datum/atom_hud/hud = GLOB.huds[new_hud]
			hud.show_to(user)
		return .
	var/datum/atom_hud/hud = GLOB.huds[hud_type]
	hud.show_to(user)

/obj/item/gun_module/rail/hud/proc/remove_hud(mob/user)
	if(!granted)
		return
	granted = FALSE
	if(islist(hud_type))
		for(var/new_hud in hud_type)
			var/datum/atom_hud/hud = GLOB.huds[new_hud]
			hud.hide_from(user)
		return .
	var/datum/atom_hud/hud = GLOB.huds[hud_type]
	hud.hide_from(user)

/obj/item/gun_module/rail/hud/medical
	name = "med hud scope"
	desc = "Коллиматорный прицел с медицинским ИЛС, предназначенный для установки на прицельную планку стрелкового оружия."
	icon_state = "coll_med"
	item_state = "coll_med"
	overlay_state = "coll_med_o"
	overlay_offset = list("x" = -5, "y" = 0)
	hud_type = DATA_HUD_MEDICAL_ADVANCED
	class = GUN_MODULE_CLASS_PISTOL_RAIL | GUN_MODULE_CLASS_SHOTGUN_RAIL | GUN_MODULE_CLASS_RIFLE_RAIL | GUN_MODULE_CLASS_SNIPER_RAIL
	origin_tech = "biotech=2;magnets=3;combat=1;programming=1"
	custom_price = PAYCHECK_LOWER

/obj/item/gun_module/rail/hud/medical/get_ru_names()
	return list(
		NOMINATIVE = "коллиматор с медицинским ИЛС",
		GENITIVE = "коллиматора с медицинским ИЛС",
		DATIVE = "коллиматору с медицинским ИЛС",
		ACCUSATIVE = "коллиматор с медицинским ИЛС",
		INSTRUMENTAL = "коллиматором с медицинским ИЛС",
		PREPOSITIONAL = "коллиматоре с медицинским ИЛС",
	)

/obj/item/gun_module/rail/hud/security
	name = "security hud scope"
	desc = "Коллиматорный прицел с охранным ИЛС, предназначенный для установки на прицельную планку стрелкового оружия."
	icon_state = "coll_sec"
	item_state = "coll_sec"
	overlay_state = "coll_sec_o"
	overlay_offset = list("x" = -5, "y" = 0)
	hud_type = DATA_HUD_SECURITY_ADVANCED
	class = GUN_MODULE_CLASS_PISTOL_RAIL | GUN_MODULE_CLASS_SHOTGUN_RAIL | GUN_MODULE_CLASS_RIFLE_RAIL | GUN_MODULE_CLASS_SNIPER_RAIL
	origin_tech = "combat=2;magnets=3;programming=1;materials=1"
	custom_price = 1.5 * PAYCHECK_LOWER

/obj/item/gun_module/rail/hud/security/get_ru_names()
	return list(
		NOMINATIVE = "коллиматор с охранным ИЛС",
		GENITIVE = "коллиматора с охранным ИЛС",
		DATIVE = "коллиматору с охранным ИЛС",
		ACCUSATIVE = "коллиматор с охранным ИЛС",
		INSTRUMENTAL = "коллиматором с охранным ИЛС",
		PREPOSITIONAL = "коллиматоре с охранным ИЛС",
	)


/**
 * MARK: Ammo counter
 */
/obj/item/gun_module/rail/hud/ammo_counter
	name = "ammo counter"
	desc = "Дисплей подсчета боеприпасов оружия."
	icon_state = "counter"
	item_state = "counter"
	overlay_state = "counter_o"
	overlay_offset = list("x" = -5, "y" = 0)
	class = GUN_MODULE_CLASS_PISTOL_RAIL | GUN_MODULE_CLASS_SHOTGUN_RAIL | GUN_MODULE_CLASS_RIFLE_RAIL | GUN_MODULE_CLASS_SNIPER_RAIL
	origin_tech = "combat=2;magnets=2"
	custom_price = PAYCHECK_LOWER
	var/atom/movable/screen/ammo_counter/counter_element = null
	var/mutable_appearance/counter_label

/obj/item/gun_module/rail/hud/ammo_counter/Initialize(mapload)
	. = ..()
	counter_element = new()

/obj/item/gun_module/rail/hud/ammo_counter/Destroy()
	. = ..()
	QDEL_NULL(counter_element)

/obj/item/gun_module/rail/hud/ammo_counter/get_ru_names()
	return list(
		NOMINATIVE = "дисплей подсчета боеприпасов",
		GENITIVE = "дисплея подсчета боеприпасов",
		DATIVE = "дисплею подсчета боеприпасов",
		ACCUSATIVE = "дисплей подсчета боеприпасов",
		INSTRUMENTAL = "дисплеем подсчета боеприпасов",
		PREPOSITIONAL = "дисплее подсчета боеприпасов",
	)

/obj/item/gun_module/rail/hud/ammo_counter/grant_hud(mob/user)
	if(granted)
		return
	granted = TRUE
	update_ammo_count(gun, user)
	RegisterSignal(gun, COMSIG_GUN_AFTER_PROCESS_FIRE, PROC_REF(process_fire))
	RegisterSignal(gun, COMSIG_GUN_RELOAD, PROC_REF(update_ammo_count))
	RegisterSignal(gun, COMSIG_GUN_UNLOAD, PROC_REF(update_ammo_count))


/obj/item/gun_module/rail/hud/ammo_counter/remove_hud(mob/user)
	if(!granted)
		return
	granted = FALSE
	UnregisterSignal(gun, list(COMSIG_GUN_AFTER_PROCESS_FIRE, COMSIG_GUN_RELOAD, COMSIG_GUN_UNLOAD))
	update_counter_maptext(user, gun, null)

/obj/item/gun_module/rail/hud/ammo_counter/proc/process_fire(obj/item/gun/target_gun, target, mob/user)
	SIGNAL_HANDLER
	update_ammo_count(target_gun, user)

/obj/item/gun_module/rail/hud/ammo_counter/proc/update_ammo_count(obj/item/gun/target_gun, mob/user)
	SIGNAL_HANDLER
	var/ammo_count_text = target_gun.get_ammo_counter_text()
	update_counter_maptext(user, target_gun, ammo_count_text)

/obj/item/gun_module/rail/hud/ammo_counter/proc/update_counter_maptext(mob/user, obj/item/gun/target_gun, text)
	if(counter_label)
		counter_element.cut_overlay(counter_label)
		counter_label = null

	if(text)
		counter_label = new()
		counter_label.maptext = MAPTEXT("<span style='text-align: center; font-size: 5pt'>[text]</span>")
		counter_label.transform = counter_label.transform.Translate(2, 8)
		counter_element.add_overlay(counter_label)
		user.client.screen |= counter_element
	else if(user && user.client)
		user.client.screen -= counter_element

/atom/movable/screen/ammo_counter
	name = "Количество выстрелов"
	icon_state = "ammo_counter"
	screen_loc = ui_ammo_counter
