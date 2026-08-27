/// Basic pod speed
#define POD_LOW_THRUST_DELAY (0.85 SECONDS)
#define POD_BASE_MOVE_DELAY (0.15 SECONDS)
#define POD_SPEED_HIGH (0.12 SECONDS)
#define POD_SPEED_NORMAL (0.15 SECONDS)
#define POD_SPEED_SLOW (0.18 SECONDS)
/// Speed modifier for gravity area
#define POD_GRAVITY_SPEED_MOD 2.5 // basic 0.4 seconds
/// Eject occupant from spacepod from outside by grab attack
#define POD_OCCUPANT_EJECT_DURATION (5 SECONDS)
/// Passenger loading from outside by drag and drop
#define POD_OCCUPANT_INSERT_DURATION (5 SECONDS)
/// Passenger or pilot enter into spacepod duration
#define POD_ENTER_DURATION (4 SECONDS)

// MARK: Basic spacepod
/obj/spacepod2
	name = "not complete spacepod"
	desc = "Незавершенный космический челнок."
	icon = 'icons/goonstation/48x48/pods.dmi'
	icon_state = "pod_civ"
	density = TRUE
	move_resist = MOVE_FORCE_EXTREMELY_STRONG
	move_force = MOVE_FORCE_VERY_STRONG
	resistance_flags = ACID_PROOF
	movement_type = FLYING
	layer = BEHIND_MOB_LAYER
	infra_luminosity = 15

	/// Current pilot
	var/mob/living/pilot = null
	/// List of passengers into pod
	var/list/mob/passengers = list()
	/// Maximum of passengers count
	var/max_passengers = 0
	/// Cabin internal storage
	var/obj/item/storage/internal/cargo_hold

	/// Internal pod system
	var/datum/spacepod_systems/systems = null

	/// Air in cabin
	var/datum/gas_mixture/cabin_air
	/// Air tank for cabin
	var/obj/machinery/portable_atmospherics/canister/internal_tank
	/// Enable internal tank flag
	var/use_internal_tank = FALSE

	/// Frame integrity
	max_integrity = 300
	/// Enable external lights
	var/lights = FALSE
	/// External lights power
	var/lights_power = 6
	/// Pod door unlocked flag
	var/unlocked = TRUE
	/// Complete assembly flag
	var/assemble_process = TRUE
	/// Hant state flag
	var/hatch_opened = FALSE

	/// Movement delay (use smaller value for higher speed)
	var/move_delay = POD_SPEED_NORMAL
	/// Movement cooldown
	COOLDOWN_DECLARE(spacepod_move_cooldown)
	/// Ion trail effect
	var/datum/effect_system/trail_follow/spacepod/ion_trail

	// Actions
	var/datum/action/innate/pod2/pod_eject/eject_action = new
	var/datum/action/innate/pod2/pod_eject/passanger_eject = new
	var/datum/action/innate/pod2/pod_toggle_lights/lights_action = new
	var/datum/action/innate/pod2/pod_panel/panel_action = new

	// tgui
	var/datum/ui_module/spacepod_control_panels/control_panels


/obj/spacepod2/get_ru_names()
	return alist(
		NOMINATIVE = "космический челнок",
		GENITIVE = "космического челнока",
		DATIVE = "космическому челноку",
		ACCUSATIVE = "космический челнок",
		INSTRUMENTAL = "космическим челноком",
		PREPOSITIONAL = "космическом челноке",
	)

/obj/spacepod2/Initialize(mapload)
	. = ..()
	bound_width = 64
	bound_height = 64
	create_internal_system()
	add_cabin()
	add_airtank()
	GLOB.spacepods_list += src
	cargo_hold = new/obj/item/storage/internal(src)
	cargo_hold.w_class = 5 //so you can put bags in
	cargo_hold.storage_slots = 4
	cargo_hold.max_w_class = 5
	cargo_hold.max_combined_w_class = 14
	START_PROCESSING(SSobj, src)
	ion_trail = new
	ion_trail.set_up(src)
	ion_trail.start()
	control_panels = new()
	control_panels.pod = src

/obj/spacepod2/proc/create_internal_system()
	systems = new()
	return systems

/obj/spacepod2/proc/add_cabin()
	cabin_air = new
	cabin_air.set_temperature(T20C)
	cabin_air.volume = 200
	cabin_air.set_oxygen(O2STANDARD * cabin_air.volume / (R_IDEAL_GAS_EQUATION * cabin_air.temperature()))
	cabin_air.set_nitrogen(N2STANDARD * cabin_air.volume / (R_IDEAL_GAS_EQUATION * cabin_air.temperature()))
	return cabin_air

/obj/spacepod2/proc/add_airtank()
	internal_tank = new /obj/machinery/portable_atmospherics/canister/air(src)
	return internal_tank

/obj/spacepod2/Destroy()
	QDEL_NULL(cargo_hold)
	QDEL_NULL(systems)
	QDEL_NULL(cabin_air)
	QDEL_NULL(internal_tank)
	QDEL_NULL(ion_trail)
	QDEL_NULL(eject_action)
	QDEL_NULL(passanger_eject)
	QDEL_NULL(lights_action)
	QDEL_NULL(panel_action)
	QDEL_NULL(control_panels)
	occupant_sanity_check()
	if(pilot)
		eject_pilot()
	if(passengers)
		for(var/mob/passenger in passengers)
			eject_passenger(passenger)
	GLOB.spacepods_list -= src
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/spacepod2/examine(mob/user)
	. = ..()
	if(assemble_process)
		. += span_notice("Сборка пода не завершена.")
		var/list/errors = systems.check_complete()
		if(length(errors) > 0)
			for(var/error_msg in errors)
				. += error_msg
			return
		. += span_notice("Для завершения сборки используйте мультитул.")

	if(hatch_opened)
		. += span_notice("Люк техобслуживания открыт.")


// MARK: Assemble procs
/obj/spacepod2/multitool_act(mob/living/user, obj/item/tool)
	if(!assemble_process)
		return ..()
	. = TRUE
	var/list/assemble_errors = systems.check_complete()
	if(length(assemble_errors) > 0)
		to_chat(user, span_warning("Сборка не завершена, осмотрите челнок чтобы узнать какие детали отсутствуют для завершения сборки."))
		return
	var/new_name = tgui_input_text(user, "Название челнока", "Задать название челнока", max_length = MAX_NAME_LEN, encode = TRUE)
	if(length(new_name) == 0 || !assemble_process)
		return
	var/new_desc = tgui_input_text(user, "Описание челнока", "Задать описание челнока", max_length = MAX_MESSAGE_LEN, encode = TRUE)
	if(length(new_desc) == 0 || !assemble_process)
		return
	name = new_name
	desc = new_desc
	ru_names = alist(
		NOMINATIVE = "космический челнок \"[new_name]\"",
		GENITIVE = "космического челнока \"[new_name]\"",
		DATIVE = "космическому челноку \"[new_name]\"",
		ACCUSATIVE = "космический челнок \"[new_name]\"",
		INSTRUMENTAL = "космическим челноком \"[new_name]\"",
		PREPOSITIONAL = "космическом челноке \"[new_name]\"",
	)
	assemble_process = FALSE

/obj/spacepod2/crowbar_act(mob/living/user, obj/item/tool)
	if(assemble_process)
		. = TRUE
		var/obj/item/spacepod_module/extracted_module = tgui_input_list(user, "Выберите модуль для удаления:", "Удаление модуля", systems.modules)
		if(extracted_module == null || extracted_module.systems == null)
			return
		systems.remove_module(src, extracted_module)
		extracted_module.forceMove(src.loc)
		to_chat(user, span_notice("Модуль [extracted_module.name] извлечен."))

	if(!unlocked)
		return ..()

	. = TRUE
	if(hatch_opened)
		hatch_opened = FALSE
		to_chat(user, span_notice("Люк техобслуживания закрыт."))
	else
		hatch_opened = TRUE
		to_chat(user, span_notice("Люк техобслуживания открыт."))


/obj/spacepod2/attackby(obj/item/item, mob/living/user, list/modifiers)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(assemble_process && istype(item, /obj/item/spacepod_module))
		var/obj/item/spacepod_module/module_obj = item
		add_fingerprint(user)
		if(!user.drop_transfer_item_to_loc(item, src))
			return ..()
		var/obj/item/spacepod_module/installed_module = module_obj.install_to(user, src)
		if(installed_module == null)
			item.forceMove(src.loc)
			return ..()
		systems.add_module(src, installed_module)
		to_chat(user, span_notice("Модуль [installed_module.name] установлен."))
		update_icon(UPDATE_ICON_STATE)
		return ATTACK_CHAIN_BLOCKED_ALL

	if(!hatch_opened)
		return ..()

	// attach gun
	if(isgun(item) && systems.weapon != null)
		if(systems.weapon.install_gun(item))
			if(!user.drop_transfer_item_to_loc(item, src))
				return ..()
			item.forceMove(src)
			update_icon(UPDATE_ICON_STATE)
			return ATTACK_CHAIN_BLOCKED_ALL

	// sitch to assemble mode
	if(ismultitool(item))
		to_chat(user, span_notice("Системы космического челнока переведены в режим сборки."))
		assemble_process = TRUE
		return ATTACK_CHAIN_BLOCKED_ALL

	// refill fuel
	if(istype(item, /obj/item/tank/internals))
		var/obj/item/tank/internals/fuel_tank = item
		if(fuel_tank.air_contents.toxins() <= 0)
			to_chat(user, span_notice("Нет нужного топлива!"))
			return ATTACK_CHAIN_BLOCKED_ALL

		var availableFuel = fuel_tank.air_contents.toxins() * 10
		var/last_fuel = systems.fill_fuel_tanks(availableFuel)
		fuel_tank.air_contents.set_toxins(last_fuel / 10)
		to_chat(user, span_notice("Заправлено [availableFuel - last_fuel] топлива из [availableFuel]."))
		return ATTACK_CHAIN_BLOCKED_ALL

	// charge battery
	if(iscell(item) && systems.battery != null)
		var/charge_rate = 0.1
		var/obj/item/stock_parts/cell/cell_item = item
		var/free_charge = systems.battery.power_capacity - systems.battery.power
		var/used_charge = min(cell_item.charge * charge_rate, free_charge)
		systems.battery.power += used_charge
		cell_item.charge -= used_charge / charge_rate
		to_chat(user, span_notice("Аккумуляторная батарея заряжена на [used_charge] Ватт."))

	return ..()

#define ACTION_CARGO_ACCESS "Доступ к хранилищу"
#define ACTION_REMOVE_PRIMARY_WEAPON "Извлечь основное вооружение"
#define ACTION_REMOVE_SECONDARY_WEAPON "Извлечь дополнительное вооружение"

/obj/spacepod2/attack_hand(mob/user)
	if(user.a_intent == INTENT_GRAB && unlocked)
		eject_any_occupant(user)

	if(hatch_opened)
		var/list/options = list()
		options += ACTION_CARGO_ACCESS
		if(systems.weapon != null)
			if(systems.weapon.primary.weapon != null)
				options += ACTION_REMOVE_PRIMARY_WEAPON
			if(systems.weapon.secondary.weapon != null)
				options += ACTION_REMOVE_SECONDARY_WEAPON

		var/choice = length(options) == 1 ? options[1] : tgui_input_list(user, "Что вы хотите сделать?", "Доступ к челноку через люк", options)
		if(!choice)
			return
		switch(choice)
			if(ACTION_CARGO_ACCESS)
				cargo_hold.open(user)
			if(ACTION_REMOVE_PRIMARY_WEAPON)
				if(systems.weapon != null)
					remove_gun_from_systems(user, systems.weapon.primary.weapon)
			if(ACTION_REMOVE_SECONDARY_WEAPON)
				if(systems.weapon != null)
					remove_gun_from_systems(user, systems.weapon.secondary.weapon)

#undef ACTION_CARGO_ACCESS
#undef ACTION_REMOVE_PRIMARY_WEAPON
#undef ACTION_REMOVE_SECONDARY_WEAPON

/obj/spacepod2/proc/remove_gun_from_systems(mob/user, obj/item/gun/selected_gun)
	if(selected_gun == null)
		to_chat(user, span_notice("Вооружение не установлено."))
		return
	var/obj/item/gun/removed_gun = systems.weapon.remove_gun(selected_gun)
	if(removed_gun == null)
		to_chat(user, span_notice("Вооружение не установлено."))
		return
	removed_gun.forceMove(src.loc)
	to_chat(user, span_notice("Вы извлекаете [removed_gun.declent_ru(NOMINATIVE)] из космического челнока."))


// MARK: Process (update)
/obj/spacepod2/process(seconds_per_tick)
	give_air()
	regulate_temp()
	systems.process_work(seconds_per_tick, src)

/obj/spacepod2/proc/give_air()
	if(!internal_tank)
		return
	var/datum/gas_mixture/tank_air = internal_tank.return_obj_air()
	var/release_pressure = ONE_ATMOSPHERE
	var/cabin_pressure = cabin_air.return_pressure()
	var/pressure_delta = min(release_pressure - cabin_pressure, (tank_air.return_pressure() - cabin_pressure)/2)
	var/transfer_moles = 0
	if(pressure_delta > 0) //cabin pressure lower than release pressure
		if(tank_air.temperature() > 0)
			transfer_moles = pressure_delta * cabin_air.return_volume() / (cabin_air.temperature() * R_IDEAL_GAS_EQUATION)
			var/datum/gas_mixture/removed = tank_air.remove(transfer_moles)
			cabin_air.merge(removed)
		return

	//cabin pressure higher than release pressure
	var/turf/location = get_turf(src)
	var/datum/gas_mixture/t_air = location.get_readonly_air()
	pressure_delta = cabin_pressure - release_pressure

	if(t_air)
		pressure_delta = min(cabin_pressure - t_air.return_pressure(), pressure_delta)

	if(pressure_delta <= 0) //if location pressure is lower than cabin pressure
		return

	transfer_moles = pressure_delta * cabin_air.return_volume() / (cabin_air.temperature() * R_IDEAL_GAS_EQUATION)
	var/datum/gas_mixture/removed = cabin_air.remove(transfer_moles)
	if(t_air)
		location.blind_release_air(removed)
	else //just delete the cabin gas, we're in space or some shit
		qdel(removed)

/obj/spacepod2/proc/regulate_temp()
	if(cabin_air && cabin_air.return_volume() > 0)
		var/delta = cabin_air.temperature() - T20C
		cabin_air.set_temperature(max(0, cabin_air.temperature() - max(-10, min(10, round(delta / 4, 0.1)))))


// MARK: Passenger procs
/obj/spacepod2/AllowDrop()
	return TRUE

/obj/spacepod2/mouse_drop_receive(mob/living/dropping, mob/living/user, params)
	if(user == pilot || (user in passengers) || !isliving(user) || user.incapacitated() || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return

	// if(isobj(dropping))
	// 	load_cargo(user, dropping)
	// 	return

	if(!isliving(dropping))
		return

	occupant_sanity_check()

	if(dropping == user)
		enter_pod(user)
		return

	if(!unlocked)
		to_chat(user, span_danger(span_bold("Люк закрыт!")))
		return

	if(length(passengers) >= max_passengers)
		to_chat(user, span_danger(span_bold("Все пассажирские места заняты!")))
		return

	visible_message(span_danger("[user.name] начина[PLUR_ET_YUT(user)] загрузку [dropping.declent_ru(GENITIVE)] в челнок!"))
	if(!do_after(user, POD_OCCUPANT_INSERT_DURATION, dropping))
		return

	if(length(passengers) >= max_passengers)
		to_chat(user, span_danger(span_bold("Все пассажирские места заняты!")))
		return

	moved_other_inside(dropping)


/obj/spacepod2/force_eject_occupant(mob/target)
	if(target == pilot)
		eject_pilot()
	else
		eject_passenger(target)

/obj/spacepod2/proc/eject_pilot()
	pilot.forceMove(get_turf(src))
	RemovePilotActions(pilot)
	pilot = null

/obj/spacepod2/proc/eject_passenger(mob/living/passenger)
	passenger.forceMove(get_turf(src))
	passanger_eject.Remove(passenger)
	passengers -= passenger

/obj/spacepod2/proc/eject_any_occupant(mob/user)
	var/mob/living/target
	if(pilot)
		target = pilot
	else if(length(passengers) > 0)
		target = passengers[1]

	if(!istype(target))
		return
	src.visible_message(
		span_warning("[user] пытается открыть дверь и вытащить [target] из [declent_ru(GENITIVE)]!"),
		span_warning("Вы видите, как [user] пытается открыть дверь!")
	)
	if(!do_after(user, POD_OCCUPANT_EJECT_DURATION, src))
		target.visible_message(
			span_warning("[user] не смог открыть дверь!"),
			span_warning("Вы не дали [user] проникнуть в [declent_ru(NOMINATIVE)]!")
		)
		return

	target.Stun(2 SECONDS)
	if(pilot)
		eject_pilot()
	else
		eject_passenger(target)
	target.visible_message(
		span_warning("[user] распахивает дверь и достаёт [target] из [declent_ru(GENITIVE)]!"),
		span_warning("Дверь распахивается, и вас выбрасывает на пол!")
	)

/obj/spacepod2/proc/moved_other_inside(mob/living/carbon/human/target)
	occupant_sanity_check()
	if(length(passengers) >= max_passengers)
		return

	target.forceMove(src)
	passengers += target
	target.forceMove(src)
	playsound(src, 'sound/machines/windowdoor.ogg', 50, TRUE)
	return TRUE


/obj/spacepod2/proc/enter_pod(mob/user)
	if(!ishuman(user) || user.incapacitated() || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return FALSE

	if(!unlocked)
		balloon_alert(user, "двери заблокированы!")
		return FALSE

	if(get_dist(src, user) > 2)
		balloon_alert(user, "слишком далеко!")
		return FALSE

	var/has_nuke_auth_disk = user.get_type_in_all_contents(/obj/item/disk/nuclear)
	if(has_nuke_auth_disk)
		to_chat(user, span_danger(span_bold("Диск ядерной аутентификации блокирует двери! Похоже, он не хочет попасть в челнок.")))
		return FALSE

	if(user.has_buckled_mobs()) //mob attached to us
		to_chat(user, span_warning("[user] не поместится в [declent_ru(ACCUSATIVE)] из-за прикреплённых существ!"))
		return FALSE

	move_inside(user)
	return TRUE

/obj/spacepod2/proc/move_inside(mob/living/user)
	if(!istype(user))
		log_debug("SHIT'S GONE WRONG WITH THE SPACEPOD [src] AT [x], [y], [z], AREA [get_area(src)], TURF [get_turf(src)]")
		return

	occupant_sanity_check()
	if(length(passengers) >= max_passengers && pilot != null)
		balloon_alert(user, "нет места!")
		return

	visible_message(span_notice("[user] начинает забираться в [declent_ru(ACCUSATIVE)]."))
	if(!do_after(user, POD_ENTER_DURATION, src))
		balloon_alert(user, "посадка отменена")
		return

	if(!pilot || pilot == null)
		pilot = user
		user.forceMove(src)
		GrantPilotActions(user)
		add_fingerprint(user)
		playsound(src, 'sound/machines/windowdoor.ogg', 50, TRUE)
		return

	if(length(passengers) < max_passengers)
		passengers += user
		user.forceMove(src)
		passanger_eject.Grant(user, src)
		add_fingerprint(user)
		playsound(src, 'sound/machines/windowdoor.ogg', 50, TRUE)
	else
		to_chat(user, span_notice("Вы слишком медлили. В следующий раз будьте быстрее."))

/obj/spacepod2/proc/occupant_sanity_check()  // going to have to adjust this later for cargo refactor
	if(!passengers)
		return
	if(length(passengers) > max_passengers)
		for(var/i = length(passengers); i >= max_passengers; i--)
			var/mob/occupant = passengers[i - 1]
			occupant.forceMove(get_turf(src))
			log_debug("##SPACEPOD WARNING: passengers EXCEED CAP: MAX passengers [max_passengers], passengers [english_list(passengers)], TURF [get_turf(src)] | AREA [get_area(src)] | COORDS [x], [y], [z]")
			passengers[i - 1] = null

	for(var/mob/passenger in passengers)
		if(!ismob(passenger))
			passenger.forceMove(get_turf(src))
			log_debug("##SPACEPOD WARNING: NON-MOB OCCUPANT [passenger], TURF [get_turf(src)] | AREA [get_area(src)] | COORDS [x], [y], [z]")
			passengers -= passenger
		else if(passenger.loc != src)
			log_debug("##SPACEPOD WARNING: OCCUPANT [passenger] ESCAPED, TURF [get_turf(src)] | AREA [get_area(src)] | COORDS [x], [y], [z]")
			passengers -= passenger

/obj/spacepod2/proc/exit_pod(mob/user)
	if(user.stat != CONSCIOUS) // unconscious people can't let themselves out
		return

	occupant_sanity_check()

	if(HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		to_chat(user, span_notice("Вы пытаетесь выбраться из [declent_ru(GENITIVE)]. Это займет две минуты."))
		if(pilot && pilot != user)
			to_chat(pilot, span_warning("[user] пытается выбраться из [declent_ru(GENITIVE)]."))
		if(!do_after(user, 2 MINUTES, src))
			return

	if(user == pilot)
		eject_pilot()
	else if(user in passengers)
		eject_passenger(user)

	to_chat(user, span_notice("Вы выбрались из [declent_ru(GENITIVE)]."))


// MARK: Attack procs
/obj/spacepod2/proc/click_action(atom/target, mob/user, list/modifiers)
	if(systems.weapon == null)
		return // weapons not installed

	if(!systems.weapon.connection_power_net || !systems.weapon.enable)
		return // weapon module offline

	var/datum/spacepod_weapon_slot/selected_gun = null
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		selected_gun = systems.weapon.secondary
	else
		selected_gun = systems.weapon.primary

	if(selected_gun == null)
		return // selected gun not exists
	if(selected_gun.safety || selected_gun.charging)
		return // safety or charging process

	selected_gun.weapon.fast_fire(target, user)


// MARK: Damage
/obj/spacepod2/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)
	if(damage_type != BRUTE && damage_type != BURN)
		// ignore other damage types, only brute or burn
		return ..(0, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

	// damage modules, and return remaining damage to frame
	damage_amount = systems.damage_modules(damage_amount)
	return ..(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

// MARK: Environment
/obj/spacepod2/return_obj_air()
	RETURN_TYPE(/datum/gas_mixture)
	if(!use_internal_tank)
		return null
	return cabin_air

/obj/spacepod2/proc/play_sound_to_riders(mysound)
	if(length(passengers | pilot) == 0)
		return
	var/sound/sound_entry = sound(mysound)
	sound_entry.wait = 0 //No queue
	sound_entry.channel = SSsounds.random_available_channel()
	sound_entry.volume = 50
	for(var/mob/passenger in passengers | pilot)
		passenger << sound_entry

/obj/spacepod2/proc/message_to_riders(mymessage)
	if(length(passengers | pilot) == 0)
		return
	for(var/mob/passenger in passengers | pilot)
		to_chat(passenger, mymessage)

/obj/spacepod2/hear_talk(mob/user, list/message_pieces)
	cargo_hold.hear_talk(user, message_pieces)
	..()

/obj/spacepod2/hear_message(mob/user, msg)
	cargo_hold.hear_message(user, msg)
	..()

/obj/spacepod2/proc/toggle_internal_tank(mob/user)
	if(user.incapacitated() || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return

	use_internal_tank = !use_internal_tank
	to_chat(user, span_notice("Подача воздуха: [use_internal_tank ? "из баллона" : "снаружи"]."))


// MARK: Movement
// it looks really good with default Process_Spacemove and newtonian movement actually, should make a button to turn it on/off
/obj/spacepod2/Process_Spacemove(movement_dir = NONE, continuous_move = FALSE)
	return TRUE	// obviously

/obj/spacepod2/relaymove(mob/user, direction)
	if(!COOLDOWN_FINISHED(src, spacepod_move_cooldown))
		return FALSE

	if(!pilot || user != pilot || !direction)
		COOLDOWN_START(src, spacepod_move_cooldown, 0.25 SECONDS) // Don't make it spam
		return FALSE

	. = TRUE

	var/speed_mod = systems.get_total_speed_mod()
	if(speed_mod <= 0)
		. = FALSE

	if(!.)
		COOLDOWN_START(src, spacepod_move_cooldown, 0.25 SECONDS)
		return .

	if(direction & (UP|DOWN))
		COOLDOWN_START(src, spacepod_move_cooldown, 0.25 SECONDS)
		. = zMove(direction)
		if(.)
			pilot.update_z(z) // after we moved
	else
		var/turf/next_step = get_step(src, direction)
		if(!next_step)
			COOLDOWN_START(src, spacepod_move_cooldown, 0.25 SECONDS)
			return FALSE
		var/calculated_move_delay = move_delay + POD_LOW_THRUST_DELAY * (1 - speed_mod)
		if(!no_gravity(loc))
			calculated_move_delay *=  POD_GRAVITY_SPEED_MOD
		set_dir_on_move = systems.can_maneuver()
		. = Move(next_step, direction)
		if(ISDIAGONALDIR(direction) && loc == next_step)
			calculated_move_delay *= sqrt(2)
		set_glide_size(DELAY_TO_GLIDE_SIZE(calculated_move_delay))
		COOLDOWN_START(src, spacepod_move_cooldown, calculated_move_delay)

	// if(. && equipment_system.cargo_system)
	// 	for(var/atom/pod_loc as anything in locs)
	// 		for(var/obj/item/item in pod_loc.contents)
	// 			equipment_system.cargo_system.passover(item)


// MARK: One engine pod
/obj/spacepod2/one_engine
	name = "one engine spacepod"
	desc = "Однодвигательный космический челнок."
	assemble_process = FALSE

/obj/spacepod2/one_engine/create_internal_system()
	. = ..()
	var/obj/item/spacepod_module/battery/battery = new /obj/item/spacepod_module/battery/full(src)
	systems.add_module(src, battery)
	// fueltank
	var/obj/item/spacepod_module/fuel_tank/large/central_fuel_tank = new /obj/item/spacepod_module/fuel_tank/large/full(src)
	central_fuel_tank.id = "central_fueltank"
	central_fuel_tank.name = "Центральный топливный бак"
	systems.add_module(src, central_fuel_tank)
	// engines
	var/obj/item/spacepod_module/fuel_tank/engine/apu/apu = new(src)
	var/obj/item/spacepod_module/fuel_tank/engine/central_engine = new("engine_central")
	central_engine.name = "Центральный двигатель"
	// Fuel pumps
	// central fueltank - apu
	var/obj/item/spacepod_module/fuel_pump/pump_apu = new(src)
	pump_apu.id = "pump_central_fueltanktank_to_apu"
	pump_apu.name = "Топливный насос из центрального бака в ВСУ"
	pump_apu.source_tank = central_fuel_tank
	pump_apu.destination_tank = apu
	systems.add_module(src, pump_apu)
	// central fueltank - central engine
	var/obj/item/spacepod_module/fuel_pump/pump_central_engine = new(src)
	pump_central_engine.id = "pump_central_fueltank_to_engine_central"
	pump_central_engine.name = "Топливный насос из центрального бака в центральный двигатель"
	pump_central_engine.source_tank = central_fuel_tank
	pump_central_engine.destination_tank = central_engine
	systems.add_module(src, pump_central_engine)
	// Add engines after fuel pumps
	systems.add_module(src, apu)
	systems.add_module(src, central_engine)
	// Gyroscope
	var/obj/item/spacepod_module/gyroscope/gyro = new(src)
	systems.add_module(src, gyro)
	// Armor
	var/obj/item/spacepod_module/armor/fore_armor = new /obj/item/spacepod_module/armor/light(src)
	fore_armor.id = "fore_armor"
	fore_armor.name = "Носовая броня"
	systems.add_module(src, fore_armor)
	var/obj/item/spacepod_module/armor/aft_armor = new /obj/item/spacepod_module/armor/light(src)
	aft_armor.id = "aft_armor"
	aft_armor.name = "Кормовая броня"
	systems.add_module(src, aft_armor)


// MARK: Two engine
/obj/spacepod2/two_engine
	name = "two engine spacepod"
	desc = "Двухдвигательный космический челнок."
	move_delay = POD_SPEED_HIGH
	assemble_process = FALSE

/obj/spacepod2/two_engine/create_internal_system()
	. = ..()
	systems.add_module(src, new /obj/item/spacepod_module/battery/full(src))
	// fuel tanks
	var/obj/item/spacepod_module/fuel_tank/large/fuel_tank_central = new /obj/item/spacepod_module/fuel_tank/large/full(src)
	fuel_tank_central.id = "fueltank_left"
	fuel_tank_central.name = "Центральный топливный бак"
	systems.add_module(src, fuel_tank_central)
	var/obj/item/spacepod_module/fuel_tank/fuel_tank_right = new /obj/item/spacepod_module/fuel_tank/full(src)
	fuel_tank_right.id = "fueltank_right"
	fuel_tank_right.name = "Правый топливный бак"
	systems.add_module(src, fuel_tank_right)
	var/obj/item/spacepod_module/fuel_tank/fuel_tank_left = new /obj/item/spacepod_module/fuel_tank/full(src)
	fuel_tank_left.id = "fueltank_left"
	fuel_tank_left.name = "Левый топливный бак"
	systems.add_module(src, fuel_tank_left)
	// Engines
	var/obj/item/spacepod_module/fuel_tank/engine/apu/apu = new(src)
	var/obj/item/spacepod_module/fuel_tank/engine/engine_right = new(src)
	engine_right.id = "engine_right"
	engine_right.name = "Правый двигатель"
	var/obj/item/spacepod_module/fuel_tank/engine/engine_left = new(src)
	engine_left.id = "engine_left"
	engine_left.name = "Левый двигатель"
	// Fuel pumps
	// central fueltank - apu
	var/obj/item/spacepod_module/fuel_pump/pump_central_to_apu = new(src)
	pump_central_to_apu.id = "pump_central_fueltanktank_to_apu"
	pump_central_to_apu.name = "Топливный насос из центрального бака в ВСУ"
	pump_central_to_apu.source_tank = fuel_tank_central
	pump_central_to_apu.destination_tank = apu
	systems.add_module(src, pump_central_to_apu)
	// central fueltank - right engine
	var/obj/item/spacepod_module/fuel_pump/pump_central_to_right_engine = new(src)
	pump_central_to_right_engine.id = "pump_central_fueltank_to_engine_right"
	pump_central_to_right_engine.name = "Топливный насос из центрального бака в правый двигатель"
	pump_central_to_right_engine.source_tank = fuel_tank_central
	pump_central_to_right_engine.destination_tank = engine_right
	systems.add_module(src, pump_central_to_right_engine)
	// central fueltank - left engine
	var/obj/item/spacepod_module/fuel_pump/pump_central_to_left_engine = new(src)
	pump_central_to_left_engine.id = "pump_central_fueltank_to_engine_left"
	pump_central_to_left_engine.name = "Топливный насос из центрального бака в левый двигатель"
	pump_central_to_left_engine.source_tank = fuel_tank_central
	pump_central_to_left_engine.destination_tank = engine_left
	systems.add_module(src, pump_central_to_left_engine)
	// right fueltank - central fueltank
	var/obj/item/spacepod_module/fuel_pump/pump_right_to_central = new(src)
	pump_right_to_central.id = "pump_right_fueltank_to_central_fueltank"
	pump_right_to_central.name = "Топливный насос из правого бака в центральный бак"
	pump_right_to_central.source_tank = fuel_tank_right
	pump_right_to_central.destination_tank = fuel_tank_central
	systems.add_module(src, pump_right_to_central)
	// left fueltank - central fueltank
	var/obj/item/spacepod_module/fuel_pump/pump_left_to_central = new(src)
	pump_left_to_central.id = "pump_left_fueltank_to_central_fueltank"
	pump_left_to_central.name = "Топливный насос из левого бака в центральный бак"
	pump_left_to_central.source_tank = fuel_tank_left
	pump_left_to_central.destination_tank = fuel_tank_central
	systems.add_module(src, pump_left_to_central)
	// right fueltank - right engine
	var/obj/item/spacepod_module/fuel_pump/pump_right_to_right_engine = new(src)
	pump_right_to_right_engine.id = "pump_right_fueltank_to_right_engine"
	pump_right_to_right_engine.name = "Топливный насос из правого бака в правый двигатель"
	pump_right_to_right_engine.source_tank = fuel_tank_right
	pump_right_to_right_engine.destination_tank = engine_right
	systems.add_module(src, pump_right_to_right_engine)
	// left fueltank - left engine
	var/obj/item/spacepod_module/fuel_pump/pump_left_to_left_engine = new(src)
	pump_left_to_left_engine.id = "pump_left_fueltank_to_left_engine"
	pump_left_to_left_engine.name = "Топливный насос из левого бака в левый двигатель"
	pump_left_to_left_engine.source_tank = fuel_tank_left
	pump_left_to_left_engine.destination_tank = engine_left
	systems.add_module(src, pump_left_to_left_engine)
	// Add engine after pumps
	systems.add_module(src, apu)
	systems.add_module(src, engine_right)
	systems.add_module(src, engine_left)
	// Gyroscope
	var/obj/item/spacepod_module/gyroscope/gyro = new(src)
	systems.add_module(src, gyro)
	// Armor
	var/obj/item/spacepod_module/armor/fore_armor = new /obj/item/spacepod_module/armor/heavy(src)
	fore_armor.id = "fore_armor"
	fore_armor.name = "Носовая броня"
	systems.add_module(src, fore_armor)
	var/obj/item/spacepod_module/armor/aft_armor = new /obj/item/spacepod_module/armor/heavy(src)
	aft_armor.id = "aft_armor"
	aft_armor.name = "Кормовая броня"
	systems.add_module(src, aft_armor)
	var/obj/item/spacepod_module/armor/port_side_armor = new /obj/item/spacepod_module/armor/heavy(src)
	port_side_armor.id = "port_side_armor"
	port_side_armor.name = "Броня левого борта"
	systems.add_module(src, port_side_armor)
	var/obj/item/spacepod_module/armor/starboard_side_armor = new /obj/item/spacepod_module/armor/heavy(src)
	starboard_side_armor.id = "starboard_side_armor"
	starboard_side_armor.name = "Броня правого борта"
	systems.add_module(src, starboard_side_armor)


// MARK: Civilian spacepod
/obj/spacepod2/one_engine/civilian
	name = "wanderer spacepod"
	desc = "Стильный гражданский космический челнок \"Странник\""

/obj/spacepod2/one_engine/civilian/get_ru_names()
	return alist(
		NOMINATIVE = "космический челнок \"Странник\"",
		GENITIVE = "космического челнока \"Странник\"",
		DATIVE = "космическому челноку \"Странник\"",
		ACCUSATIVE = "космический челнок \"Странник\"",
		INSTRUMENTAL = "космическим челноком \"Странник\"",
		PREPOSITIONAL = "космическом челноке \"Странник\"",
	)


// MARK: Security spacepod
/obj/spacepod2/two_engine/raptor
	name = "raptor spacepod"
	desc = "Бронированный челнок службы безопасности \"Раптор\"."
	icon_state = "pod_dece"
	max_integrity = 450

/obj/spacepod2/two_engine/raptor/get_ru_names()
	return alist(
		NOMINATIVE = "космический челнок \"Раптор\"",
		GENITIVE = "космического челнока \"Раптор\"",
		DATIVE = "космическому челноку \"Раптор\"",
		ACCUSATIVE = "космический челнок \"Раптор\"",
		INSTRUMENTAL = "космическим челноком \"Раптор\"",
		PREPOSITIONAL = "космическом челноке \"Раптор\"",
	)

/obj/spacepod2/two_engine/raptor/create_internal_system()
	. = ..()
	var/obj/item/spacepod_module/weapon/turret/gun_turret = new(src)
	systems.add_module(src, gun_turret)
	var/obj/item/gun/energy/disabler/disabler_gun = new(src)
	gun_turret.install_gun(disabler_gun)
	var/obj/item/gun/energy/laser/laser_gun = new(src)
	gun_turret.install_gun(laser_gun)
	systems.add_module(src, new /obj/item/spacepod_module/passenger_seat(src))
	systems.add_module(src, new /obj/item/spacepod_module/fire_extingusher(src))


// MARK: Actions
/obj/spacepod2/proc/GrantPilotActions(mob/living/user)
	eject_action.Grant(user, src)
	lights_action.Grant(user, src)
	//fire_action.Grant(user, src)
	panel_action.Grant(user, src)

/obj/spacepod2/proc/RemovePilotActions(mob/living/user)
	eject_action.Remove(user)
	lights_action.Remove(user)
	//fire_action.Remove(user)
	panel_action.Remove(user)

/datum/action/innate/pod2
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_CONSCIOUS|AB_CHECK_INCAPACITATED
	button_icon = 'icons/mob/actions/actions_mecha.dmi'
	var/obj/spacepod2/pod

/datum/action/innate/pod2/Grant(mob/living/target, obj/spacepod/spacepod)
	if(spacepod)
		pod = spacepod
	. = ..()

/datum/action/innate/pod2/Destroy()
	pod = null
	return ..()

/datum/action/innate/pod2/pod_eject
	name = "Выйти из челнока"
	button_icon_state = "mech_eject"

/datum/action/innate/pod2/pod_eject/Activate()
	pod.exit_pod(owner)

/datum/action/innate/pod2/pod_toggle_lights
	name = "Переключить прожектор"
	desc = "Переключает мощный осветительный модуль."
	button_icon_state = "mech_lights_off"

/datum/action/innate/pod2/pod_toggle_lights/Activate()
	if(!owner || !pod || pod.pilot != owner)
		return
	// pod.toggleLights(owner)
	button_icon_state = "mech_lights_[pod.lights ? "on" : "off"]"
	UpdateButtonIcon()

/datum/action/innate/pod2/pod_fire
	name = "Стрелять"
	button_icon_state = "mech_zoom_off"

/datum/action/innate/pod2/pod_fire/Activate()
	if(!owner || !pod || pod.pilot != owner)
		return
	// pod.fireWeapon(owner)

/datum/action/innate/pod2/pod_panel
	name = "Панель управления"
	button_icon_state = "mech_misc"

/datum/action/innate/pod2/pod_panel/Activate()
	if(!owner || !pod || pod.pilot != owner)
		return
	pod.control_panels.ui_interact(owner)

	// var/misc_system = tgui_input_list(owner, "Выберите систему", "Управление челноком", POD_MISC_SYSTEMS)
	// if(!misc_system)
	// 	return
	// if(!owner || !pod || pod.pilot != owner) //we check twice because of input
	// 	return
	// switch(misc_system)
	// 	if(POD_MISC_LOCK_DOOR)
	// 		pod.lock_pod(owner)
	// 	if(POD_MISC_POD_DOORS)
	// 		pod.toggleDoors(owner)
	// 	if(POD_MISC_UNLOAD_CARGO)
	// 		pod.unload(owner)
	// 	if(POD_MISC_CHECK_SEAT)
	// 		pod.checkSeat(owner)
	// 	if(POD_MISC_LOCATOR_SKAN)
	// 		pod.startScan(owner)


#undef POD_GRAVITY_SPEED_MOD
#undef POD_OCCUPANT_EJECT_DURATION
