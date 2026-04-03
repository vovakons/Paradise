#define MOVEMENT_RECHECK_COOLDOWN (0.5 SECONDS)

/obj/pod
	name = "space pod"
	desc = "Космический челнок, предназначенный для путешествий в открытом космосе"
	icon = 'icons/goonstation/48x48/pods.dmi'
	icon_state = "pod_civ"
	density = TRUE
	move_resist = MOVE_FORCE_EXTREMELY_STRONG
	move_force = MOVE_FORCE_VERY_STRONG
	resistance_flags = ACID_PROOF
	movement_type = FLYING
	layer = BEHIND_MOB_LAYER
	infra_luminosity = 15

	// Configure variables
	/// Move speed in space (without gravity) (tiles per seconds)
	var/space_speed = 1
	/// Move speed in gravity (tiles per seconds)
	var/gravity_speed = 0.25

	// Runtime variables
	/// Living who control the pod
	var/mob/living/pilot
	/// List of passengers (can't do anything inside pod)
	var/list/mob/passengers = list()
	/// Count of max passengers in pod
	var/max_passengers = 0
	/// Movement cooldown
	COOLDOWN_DECLARE(spacepod_move_cooldown)

	// Actions
	/// Pilot eject action button
	var/datum/action/innate/pod_action/pod_eject/eject_action = new
	/// Passengers eject action button
	var/datum/action/innate/pod_action/pod_eject/passanger_eject = new


/obj/pod/get_ru_names()
	return list(
		NOMINATIVE = "космический челнок",
		GENITIVE = "космического челнока",
		DATIVE = "космическому челноку",
		ACCUSATIVE = "космический челнок",
		INSTRUMENTAL = "космическим челноком",
		PREPOSITIONAL = "космическом челноке",
	)


// MARK: Init
/obj/pod/Initialize(mapload)
	. = ..()
	bound_width = 64
	bound_height = 64
	START_PROCESSING(SSobj, src)

/obj/pod/Destroy()
	evacuate_all()
	QDEL_NULL(eject_action)
	QDEL_NULL(passanger_eject)
	STOP_PROCESSING(SSobj, src)
	return ..()


// MARK: Processing
/obj/pod/process()
	. = ..()
	//TODO vakons: добавить процессинг модулей


// MARK: Occupation logic
/obj/pod/proc/move_inside(mob/living/user)
	if(!istype(user))
		log_debug("SHIT'S GONE WRONG WITH THE SPACEPOD [src] AT [x], [y], [z], AREA [get_area(src)], TURF [get_turf(src)]")

	if(pilot && length(passengers) >= max_passengers)
		balloon_alert(user, "нет места!")
		return

	visible_message(span_notice("[user] начинает забираться в [declent_ru(ACCUSATIVE)]."))
	add_fingerprint(user)
	if(!do_after(user, 4 SECONDS, src)) //await progress bar
		balloon_alert(user, "посадка отменена")
		return

	if(!pilot || pilot == null)
		enter_pilot(user)
		playsound(src, 'sound/machines/windowdoor.ogg', 50, TRUE)
		return
	// pilot occupied, try as passenger
	if(length(passengers) < max_passengers)
		enter_passenger(user)
		playsound(src, 'sound/machines/windowdoor.ogg', 50, TRUE)
		return
	// no available seat place
	to_chat(user, span_notice("Вы слишком медлили. В следующий раз будьте быстрее."))

/obj/pod/proc/exit_pod(mob/living/user)
	if(user == pilot)
		eject_pilot()
	else if(user in passengers)
		eject_passenger(user)

/obj/pod/proc/enter_pilot(mob/living/user)
	user.forceMove(src)
	eject_action.Grant(user, src)
	pilot = user

/obj/pod/proc/eject_pilot()
	pilot.forceMove(get_turf(src))
	eject_action.Remove(pilot)
	pilot = null

/obj/pod/proc/enter_passenger(mob/passenger)
	passenger.forceMove(src)
	passanger_eject.Grant(passenger, src)
	passengers += passenger

/obj/pod/proc/eject_passenger(mob/passenger)
	passenger.forceMove(get_turf(src))
	passanger_eject.Remove(passenger)
	passengers -= passenger

/obj/pod/proc/evacuate_all()
	if(pilot)
		eject_pilot()
	if(passengers)
		for(var/mob/passenger in passengers)
			eject_passenger(passenger)


//MARK: Input processing
/obj/pod/MouseDrop_T(mob/living/dropping, mob/living/user, params)
	if(user == pilot || (user in passengers) || user.incapacitated() || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return FALSE

	. = TRUE
	if(isliving(dropping))
		if(dropping != user && (dropping.stat == DEAD || dropping.incapacitated()))
			if(length(passengers) >= max_passengers && !pilot)
				to_chat(user, span_danger("<b>Этот человек не может управлять челноком!</b>"))
				return .
			if(length(passengers) < max_passengers)
				visible_message(span_danger("[user.name] начина[PLUR_ET_YUT(user)] загрузку [dropping.declent_ru(GENITIVE)] в челнок!"))
				if(do_after(user, 5 SECONDS, dropping))
					enter_passenger(dropping)
			return .

		if(dropping == user)
			move_inside(user)

	// else if(isobj(dropping))
		// load_cargo(user, dropping)


// MARK: Movement
/obj/pod/relaymove(mob/user, direction)
	if(!COOLDOWN_FINISHED(src, spacepod_move_cooldown))
		return FALSE

	if(!pilot || user != pilot || !direction)
		COOLDOWN_START(src, spacepod_move_cooldown, MOVEMENT_RECHECK_COOLDOWN)	// Don't make it spam
		return FALSE

	. = TRUE

	//TODO vakons: проверить работоспособность модулей отвечающих за движение

	if(!.)
		COOLDOWN_START(src, spacepod_move_cooldown, MOVEMENT_RECHECK_COOLDOWN)
		return .

	if(direction & (UP|DOWN))
		COOLDOWN_START(src, spacepod_move_cooldown, MOVEMENT_RECHECK_COOLDOWN)
		. = zMove(direction)
		if(.)
			pilot.update_z(z) // after we moved
		return

	var/turf/next_step = get_step(src, direction)
	if(!next_step)
		COOLDOWN_START(src, spacepod_move_cooldown, MOVEMENT_RECHECK_COOLDOWN)
		return FALSE
	var/calculated_move_delay = 1.0 / (no_gravity(loc) ? space_speed : gravity_speed)
	. = Move(next_step, direction)
	if(ISDIAGONALDIR(direction) && loc == next_step)
		calculated_move_delay *= sqrt(2)
	set_glide_size(DELAY_TO_GLIDE_SIZE(calculated_move_delay))
	COOLDOWN_START(src, spacepod_move_cooldown, calculated_move_delay)

#undef MOVEMENT_RECHECK_COOLDOWN
