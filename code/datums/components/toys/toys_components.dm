// Components for toys behaviour

/// Basic toys component
/datum/component/toy_component

/datum/component/toy_component/Initialize(...)
	if(!istoy(parent))
		return COMPONENT_INCOMPATIBLE


/// MARK: attack_self
/datum/component/toy_component/attack_self

/datum/component/toy_component/attack_self/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(invoke))

/datum/component/toy_component/attack_self/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK_SELF)

/datum/component/toy_component/attack_self/proc/invoke(obj/item/source, mob/user)
	SIGNAL_HANDLER
	return


/datum/component/toy_component/attack_self/random_sound
	var/sounds
	var/volume
	var/vary

/datum/component/toy_component/attack_self/random_sound/Initialize(sounds, volume = 100, vary = FALSE, ...)
	. = ..()
	if(islist(sounds))
		src.sounds = sounds
	else
		src.sounds = list(sounds)
	src.volume = volume
	src.vary = vary

/datum/component/toy_component/attack_self/random_sound/invoke(obj/item/source, mob/user)
	var/sound = pick(sounds)
	playsound(user.loc, sound, volume, vary)


/datum/component/toy_component/attack_self/plays_with
	var/messages

/datum/component/toy_component/attack_self/plays_with/Initialize(messages, ...)
	. = ..()
	if(islist(messages))
		src.messages = messages
	else
		src.messages = list(messages)

/datum/component/toy_component/attack_self/plays_with/invoke(obj/item/source, mob/user)
	var/message = pick(messages)
	user.visible_message(span_notice("[user] играется с [source.declent_ru(INSTRUMENTAL)]."), span_notice(message))


/datum/component/toy_component/attack_self/something_with_message
	var/verbs

/datum/component/toy_component/attack_self/something_with_message/Initialize(verbs, ...)
	. = ..()
	if(islist(verbs))
		src.verbs = verbs
	else
		src.verbs = list(verbs)

/datum/component/toy_component/attack_self/something_with_message/invoke(obj/item/source, mob/user)
	var/doverb = pick(verbs)
	user.visible_message(span_notice("[user] [doverb] с [source.declent_ru(INSTRUMENTAL)]."))


/datum/component/toy_component/attack_self/icon_visible_message
	var/messages

/datum/component/toy_component/attack_self/icon_visible_message/Initialize(messages, ...)
	. = ..()
	if(islist(messages))
		src.messages = messages
	else
		src.messages = list(messages)

/datum/component/toy_component/attack_self/icon_visible_message/invoke(obj/item/source, mob/user)
	var/message = pick(messages)
	user.visible_message("[bicon(source)] [span_notice(message)]")


/datum/component/toy_component/attack_self/to_chat_message
	var/messages

/datum/component/toy_component/attack_self/to_chat_message/Initialize(messages, ...)
	. = ..()
	if(islist(messages))
		src.messages = messages
	else
		src.messages = list(messages)

/datum/component/toy_component/attack_self/to_chat_message/invoke(obj/item/source, mob/user)
	var/message = pick(messages)
	to_chat(user, span_notice(message))


/datum/component/toy_component/attack_self/invoke_async
	var/callback

/datum/component/toy_component/attack_self/invoke_async/Initialize(callback, ...)
	. = ..()
	src.callback = callback

/datum/component/toy_component/attack_self/invoke_async/invoke(obj/item/source, mob/user)
	INVOKE_ASYNC(parent, callback, user)

// MARK: attack_hand
/datum/component/toy_component/attack_hand

/datum/component/toy_component/attack_hand/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_ATTACK_HAND, PROC_REF(check_invoke))

/datum/component/toy_component/attack_hand/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATOM_ATTACK_HAND)

/datum/component/toy_component/attack_hand/proc/check_invoke(obj/item/source, mob/user)
	SIGNAL_HANDLER
	if(source.loc == user)
		invoke(source, user)


/datum/component/toy_component/attack_hand/proc/invoke(obj/item/source, mob/user)
	return


/datum/component/toy_component/attack_hand/random_sound
	var/sounds
	var/volume
	var/vary

/datum/component/toy_component/attack_hand/random_sound/Initialize(sounds, volume = 100, vary = FALSE, ...)
	. = ..()
	if(islist(sounds))
		src.sounds = sounds
	else
		src.sounds = list(sounds)
	src.volume = volume
	src.vary = vary

/datum/component/toy_component/attack_hand/random_sound/invoke(obj/item/source, mob/user)
	var/sound = pick(sounds)
	playsound(user.loc, sound, volume, vary)


/datum/component/toy_component/attack_hand/to_chat_message
	var/messages

/datum/component/toy_component/attack_hand/to_chat_message/Initialize(messages, ...)
	. = ..()
	if(islist(messages))
		src.messages = messages
	else
		src.messages = list(messages)

/datum/component/toy_component/attack_hand/to_chat_message/invoke(obj/item/source, mob/user)
	var/message = pick(messages)
	to_chat(user, span_notice(message))


// MARK: attack
/datum/component/toy_component/attack

/datum/component/toy_component/attack/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_ATTACK, PROC_REF(invoke))

/datum/component/toy_component/attack/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK)

/datum/component/toy_component/attack/proc/invoke(obj/item/source, mob/living/target, mob/living/user, params, def_zone)
	SIGNAL_HANDLER
	return


/datum/component/toy_component/attack/random_sound
	var/sounds
	var/volume
	var/vary

/datum/component/toy_component/attack/random_sound/Initialize(sounds, volume = 100, vary = FALSE, ...)
	. = ..()
	if(islist(sounds))
		src.sounds = sounds
	else
		src.sounds = list(sounds)
	src.volume = volume
	src.vary = vary

/datum/component/toy_component/attack/random_sound/invoke(obj/item/source, mob/living/target, mob/living/user, params, def_zone)
	var/sound = pick(sounds)
	playsound(user.loc, sound, volume, vary)


/datum/component/toy_component/attack/add_hugs

/datum/component/toy_component/attack/add_hugs/invoke(obj/item/source, mob/living/target, mob/living/user, params, def_zone)
	if(iscarbon(target) && prob(10))
		target.reagents.add_reagent("hugs", 10)


/datum/component/toy_component/attack/invoke_async
	var/callback

/datum/component/toy_component/attack/invoke_async/Initialize(callback, ...)
	. = ..()
	src.callback = callback

/datum/component/toy_component/attack/invoke_async/invoke(obj/item/source, mob/living/target, mob/living/user, params, def_zone)
	INVOKE_ASYNC(parent, callback, user)


/datum/component/toy_component/attack/icon_visible_message
	var/messages

/datum/component/toy_component/attack/icon_visible_message/Initialize(messages, ...)
	. = ..()
	if(islist(messages))
		src.messages = messages
	else
		src.messages = list(messages)

/datum/component/toy_component/attack/icon_visible_message/invoke(obj/item/source, mob/living/target, mob/living/user, params, def_zone)
	var/message = pick(messages)
	user.visible_message("[bicon(parent)] [span_notice(message)]")
