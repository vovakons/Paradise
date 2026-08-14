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
	name = "space pod"
	desc = "Космический челнок, предназначенный для путешествий в открытом космосе."
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
	var/use_internal_tank = TRUE

	/// Frame integrity
	var/health = 250
	/// Enable external lights
	var/lights = FALSE
	/// External lights power
	var/lights_power = 6
	/// Pod door unlocked flag
	var/unlocked = TRUE

	/// Movement delay (use smaller value for higher speed)
	var/move_delay = POD_SPEED_NORMAL
	/// Movement cooldown
	COOLDOWN_DECLARE(spacepod_move_cooldown)
	/// Ion trail effect
	var/datum/effect_system/trail_follow/spacepod/ion_trail

	// Actions
	var/datum/action/innate/pod2/pod_eject/eject_action = new
	var/datum/action/innate/pod2/pod_eject/passanger_eject = new
	var/datum/action/innate/pod2/pod_toggle_internals/internals_action = new
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
	cargo_hold.storage_slots = 0 //You need to install cargo modules to use it.
	cargo_hold.max_w_class = 5 //fit almost anything
	cargo_hold.max_combined_w_class = 0 //you can optimize your stash with larger items
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
	QDEL_NULL(internals_action)
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
/obj/spacepod2/attack_hand(mob/user)
	if(user.a_intent == INTENT_GRAB && unlocked)
		eject_any_occupant(user)


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

/obj/spacepod2/one_engine/create_internal_system()
	. = ..()
	systems.add_module(new /datum/spacepod_module/battery/full("battery"))
	// fueltank
	var/datum/spacepod_module/fuel_tank/large/central_fuel_tank = new /datum/spacepod_module/fuel_tank/large/full("central_fueltank")
	central_fuel_tank.name = "Центральный топливный бак"
	systems.add_module(central_fuel_tank)
	// engines
	var/datum/spacepod_module/fuel_tank/engine/apu/apu = new("apu")
	var/datum/spacepod_module/fuel_tank/engine/central_engine = new("engine_central")
	central_engine.name = "Центральный двигатель"
	// Fuel pumps
	// central fueltank - apu
	var/datum/spacepod_module/fuel_pump/pump_apu = new("pump_central_fueltanktank_to_apu")
	pump_apu.name = "Топливный насос из центрального бака в ВСУ"
	pump_apu.source_tank = central_fuel_tank
	pump_apu.destination_tank = apu
	systems.add_module(pump_apu)
	// central fueltank - central engine
	var/datum/spacepod_module/fuel_pump/pump_central_engine = new("pump_central_fueltank_to_engine_central")
	pump_central_engine.name = "Топливный насос из центрального бака в центральный двигатель"
	pump_central_engine.source_tank = central_fuel_tank
	pump_central_engine.destination_tank = central_engine
	systems.add_module(pump_central_engine)
	// Add engines after fuel pumps
	systems.add_module(apu)
	systems.add_module(central_engine)
	// Gyroscope
	var/datum/spacepod_module/gyroscope/gyro = new("gyroscope")
	systems.add_module(gyro)


// MARK: Two engine
/obj/spacepod2/two_engine
	name = "two engine spacepod"
	desc = "Двухдвигательный космический челнок."
	move_delay = POD_SPEED_HIGH

/obj/spacepod2/two_engine/create_internal_system()
	. = ..()
	systems.add_module(new /datum/spacepod_module/battery/full("battery"))
	// fuel tanks
	var/datum/spacepod_module/fuel_tank/fuel_tank_central = new /datum/spacepod_module/fuel_tank/full("fueltank_left")
	fuel_tank_central.name = "Центральный топливный бак"
	systems.add_module(fuel_tank_central)
	var/datum/spacepod_module/fuel_tank/fuel_tank_right = new /datum/spacepod_module/fuel_tank/full("fueltank_right")
	fuel_tank_right.name = "Правый топливный бак"
	systems.add_module(fuel_tank_right)
	var/datum/spacepod_module/fuel_tank/fuel_tank_left = new /datum/spacepod_module/fuel_tank/full("fueltank_left")
	fuel_tank_left.name = "Левый топливный бак"
	systems.add_module(fuel_tank_left)
	// Engines
	var/datum/spacepod_module/fuel_tank/engine/apu/apu = new("apu")
	var/datum/spacepod_module/fuel_tank/engine/engine_right = new("engine_right")
	engine_right.name = "Правый двигатель"
	var/datum/spacepod_module/fuel_tank/engine/engine_left = new("engine_left")
	engine_left.name = "Левый двигатель"
	// Fuel pumps
	// central fueltank - apu
	var/datum/spacepod_module/fuel_pump/pump_central_to_apu = new("pump_central_fueltanktank_to_apu")
	pump_central_to_apu.name = "Топливный насос из центрального бака в ВСУ"
	pump_central_to_apu.source_tank = fuel_tank_central
	pump_central_to_apu.destination_tank = apu
	systems.add_module(pump_central_to_apu)
	// central fueltank - right engine
	var/datum/spacepod_module/fuel_pump/pump_central_to_right_engine = new("pump_central_fueltank_to_engine_right")
	pump_central_to_right_engine.name = "Топливный насос из центрального бака в правый двигатель"
	pump_central_to_right_engine.source_tank = fuel_tank_central
	pump_central_to_right_engine.destination_tank = engine_right
	systems.add_module(pump_central_to_right_engine)
	// central fueltank - left engine
	var/datum/spacepod_module/fuel_pump/pump_central_to_left_engine = new("pump_central_fueltank_to_engine_left")
	pump_central_to_left_engine.name = "Топливный насос из центрального бака в левый двигатель"
	pump_central_to_left_engine.source_tank = fuel_tank_central
	pump_central_to_left_engine.destination_tank = engine_left
	systems.add_module(pump_central_to_left_engine)
	// right fueltank - central fueltank
	var/datum/spacepod_module/fuel_pump/pump_right_to_central = new("pump_right_fueltank_to_central_fueltank")
	pump_right_to_central.name = "Топливный насос из правого бака в центральный бак"
	pump_right_to_central.source_tank = fuel_tank_right
	pump_right_to_central.destination_tank = fuel_tank_central
	systems.add_module(pump_right_to_central)
	// left fueltank - central fueltank
	var/datum/spacepod_module/fuel_pump/pump_left_to_central = new("pump_left_fueltank_to_central_fueltank")
	pump_left_to_central.name = "Топливный насос из левого бака в центральный бак"
	pump_left_to_central.source_tank = fuel_tank_left
	pump_left_to_central.destination_tank = fuel_tank_central
	systems.add_module(pump_left_to_central)
	// right fueltank - right engine
	var/datum/spacepod_module/fuel_pump/pump_right_to_right_engine = new("pump_right_fueltank_to_right_engine")
	pump_right_to_right_engine.name = "Топливный насос из правого бака в правый двигатель"
	pump_right_to_right_engine.source_tank = fuel_tank_right
	pump_right_to_right_engine.destination_tank = engine_right
	systems.add_module(pump_right_to_right_engine)
	// left fueltank - left engine
	var/datum/spacepod_module/fuel_pump/pump_left_to_left_engine = new("pump_left_fueltank_to_left_engine")
	pump_left_to_left_engine.name = "Топливный насос из левого бака в левый двигатель"
	pump_left_to_left_engine.source_tank = fuel_tank_left
	pump_left_to_left_engine.destination_tank = engine_left
	systems.add_module(pump_left_to_left_engine)
	// Add engine after pumps
	systems.add_module(apu)
	systems.add_module(engine_right)
	systems.add_module(engine_left)
	// Gyroscope
	var/datum/spacepod_module/gyroscope/gyro = new("gyroscope")
	systems.add_module(gyro)


// MARK: Custom spacepod
/obj/spacepod2/custom
	name = "not complete spacepod"
	desc = "Незавершенный космический челнок."
	move_delay = POD_SPEED_NORMAL
	var/assemble_process = TRUE

/obj/spacepod2/custom/examine(mob/user)
	. = ..()
	. += span_notice("Сборка пода не завершена.")
	var/list/errors = systems.check_complete()
	if(length(errors) > 0)
		for(var/error_msg in errors)
			. += error_msg
	else
		. += span_notice("Для завершения сборки используйте мультитул.")

/obj/spacepod2/custom/multitool_act(mob/living/user, obj/item/tool)
	if(!assemble_process)
		return ..()
	. = TRUE
	var/list/assemble_errors = systems.check_complete()
	if(length(assemble_errors) > 0)
		to_chat(user, span_warning("Сборка не завершена, осмотрите челнок чтобы узнать какие детали отсутствуют для завершения сборки."))
		return
	var/new_name = tgui_input_text(user, "Название челнока", "Переименовать челнок", max_length = MAX_NAME_LEN, encode = TRUE)
	if(!assemble_process)
		return
	if(length(new_name) == 0)
		return
	name = new_name
	ru_names = alist(
		NOMINATIVE = "космический челнок \"[new_name]\"",
		GENITIVE = "космического челнока \"[new_name]\"",
		DATIVE = "космическому челноку \"[new_name]\"",
		ACCUSATIVE = "космический челнок \"[new_name]\"",
		INSTRUMENTAL = "космическим челноком \"[new_name]\"",
		PREPOSITIONAL = "космическом челноке \"[new_name]\"",
	)
	assemble_process = FALSE

/obj/spacepod2/custom/attackby(obj/item/item, mob/living/user, list/modifiers)
	if(!assemble_process)
		return ..()
	if(user.a_intent == INTENT_HARM)
		return ..()
	if(istype(item, /obj/item/spacepod_module))
		var/obj/item/spacepod_module/module_obj = item
		add_fingerprint(user)
		if(!user.drop_transfer_item_to_loc(item, src))
			return ..()
		var/datum/spacepod_module/installed_module = module_obj.install_to(user, src)
		if(installed_module == null)
			item.forceMove(src.loc)
			return ..()
		qdel(item)
		systems.add_module(installed_module)
		to_chat(user, span_notice("Модуль [installed_module.name] установлен."))
		update_icon(UPDATE_ICON_STATE)
		return ATTACK_CHAIN_BLOCKED_ALL

	return ..()


// MARK: Civilian spacepod
/obj/spacepod2/one_engine/civilian
	name = "raptor spacepod"
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
	health = 600

/obj/spacepod2/two_engine/raptor/get_ru_names()
	return alist(
		NOMINATIVE = "космический челнок \"Раптор\"",
		GENITIVE = "космического челнока \"Раптор\"",
		DATIVE = "космическому челноку \"Раптор\"",
		ACCUSATIVE = "космический челнок \"Раптор\"",
		INSTRUMENTAL = "космическим челноком \"Раптор\"",
		PREPOSITIONAL = "космическом челноке \"Раптор\"",
	)


// MARK: Actions
/obj/spacepod2/proc/GrantPilotActions(mob/living/user)
	eject_action.Grant(user, src)
	internals_action.Grant(user, src)
	lights_action.Grant(user, src)
	//fire_action.Grant(user, src)
	panel_action.Grant(user, src)

/obj/spacepod2/proc/RemovePilotActions(mob/living/user)
	eject_action.Remove(user)
	internals_action.Remove(user)
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

/datum/action/innate/pod2/pod_toggle_internals
	name = "Переключить баллон"
	desc = "Переключает подачу воздуха из внутреннего баллона, защищая от вакуума и разреженной атмосферы."
	button_icon_state = "mech_internals_off"

/datum/action/innate/pod2/pod_toggle_internals/Activate()
	if(!owner || !pod || pod.pilot != owner)
		return
	// pod.toggle_internal_tank(owner)
	button_icon_state = "mech_internals_[pod.use_internal_tank ? "on" : "off"]"
	UpdateButtonIcon()

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
