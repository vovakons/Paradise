/obj/effect/proc_holder/spell/summonitem
	name = "Мгновенный призыв"
	desc = "Это заклинание позволяет вернуть ранее отмеченный предмет в вашу руку откуда угодно из Вселенной."
	school = "transmutation"
	cooldown_min = 10 SECONDS
	clothes_req = FALSE
	human_req = FALSE
	invocation = "GAR YOK"
	invocation_type = "whisper"
	level_max = 0 //cannot be improved

	var/obj/marked_item
	/// List of objects which will result in the spell stopping with the recursion search
	var/static/list/blacklisted_summons = list(/obj/machinery/computer/cryopod = TRUE, /obj/machinery/atmospherics = TRUE, /obj/structure/disposalholder = TRUE, /obj/machinery/disposal = TRUE)
	action_icon_state = "summons"

/obj/effect/proc_holder/spell/summonitem/create_new_targeting()
	return new /datum/spell_targeting/self

/obj/effect/proc_holder/spell/summonitem/cast(list/targets, mob/user = usr)
	for(var/mob/living/target in targets)
		cast_on_target(target, user)

/obj/effect/proc_holder/spell/summonitem/proc/cast_on_target(mob/living/target, mob/user)
	var/list/hand_items = list(target.get_active_hand(), target.get_inactive_hand())
	var/message
	if(!marked_item)
		link_item_to_spell(target, user, hand_items)
		return

	if(marked_item && (marked_item in hand_items))
		unlink_item_to_spell(target, user, span_notice("Вы удалили отметку с [marked_item.declent_ru(GENITIVE)], теперь вы не можете его призвать."))
		return

	if(marked_item && !marked_item.loc) //the item was destroyed at some point
		unlink_item_to_spell(target, user, hand_items, span_warning("Вы чувствуете что отмеченный предмет уничтожен."))
		return

	do_instant_summon(target, user)


/obj/effect/proc_holder/spell/summonitem/proc/link_item_to_spell(mob/living/target, mob/user, list/hand_items)
	for(var/obj/item in hand_items)
		if(is_internal_organ_brain(item)) //Yeah, sadly this doesn't work due to the organ system.
			break
		if(isitem(item))
			var/obj/item/I = item
			if(I.item_flags & ABSTRACT)
				continue

		marked_item = item
		to_chat(target, span_notice("Вы отметили [item.declent_ru(NOMINATIVE)] для вызова."))
		name = "Вызвать [item.declent_ru(NOMINATIVE)]"
		break

	if(marked_item)
		return

	if(hand_items)
		to_chat(target, span_caution("У вас нет ничего подходящего в руках чтобы отметить его для вызова."))
		return

	to_chat(target, span_notice("Вы должны держать нужный предмет в руках, чтобы пометить его для вызова."))


/obj/effect/proc_holder/spell/summonitem/proc/unlink_item_to_spell(mob/living/target, mob/user, reason)
	name = "Мгновенный призыв"
	marked_item = null
	to_chat(target, span_notice(reason))


/obj/effect/proc_holder/spell/summonitem/proc/do_instant_summon(mob/living/target, mob/user)
	var/obj/item_to_retrieve = marked_item

	if(is_type_in_typecache(item_to_retrieve.loc, blacklisted_summons))
		to_chat(target, span_warning("Неизвестная сила мешает призвать отмеченный предмет!"))
		return

	if(isturf(item_to_retrieve.loc)) // item on ground
		teleportate_item_to_target(item_to_retrieve, target)
		return

	if(ismob(item_to_retrieve.loc))
		var/mob/item_owner = item_to_retrieve.loc
		if(isexternalorgan(item_to_retrieve))
			var/obj/item/organ/external/external_organ = item_to_retrieve
			var/atom/movable/thing = external_organ.droplimb(1, DROPLIMB_SHARP)
			thing.forceMove(get_turf(item_owner))
			teleportate_item_to_target(item_to_retrieve, target)
			return
		if(is_internal_organ(item_to_retrieve))
			var/obj/item/organ/internal/external_organ = item_to_retrieve
			item_to_retrieve = external_organ.remove(item_owner)
			item_to_retrieve.forceMove(get_turf(item_owner))
			teleportate_item_to_target(item_to_retrieve, target)
			return

		if(!item_owner.drop_item_ground(item_to_retrieve, force = TRUE))
			to_chat(target, span_warning("У вас не получается призвать привязанный предмет!"))
			return

		teleportate_item_to_target(item_to_retrieve, target)
		return

	if(item_to_retrieve.forceMove(item_to_retrieve.loc))
		teleportate_item_to_target(item_to_retrieve, target)
		return

	to_chat(target, span_warning("У вас не получается призвать привязанный предмет!"))


/obj/effect/proc_holder/spell/summonitem/proc/do_instant_summon_old_variant(mob/living/target, mob/user) // Remove it later, or create old variant of speel
	var/obj/item_to_retrieve = marked_item
	var/infinite_recursion = 0 //I don't want to know how someone could put something inside itself but these are wizards so let's be safe

	while(!isturf(item_to_retrieve.loc) && infinite_recursion < 10) //if it's in something you get the whole thing.
		if(ismob(item_to_retrieve.loc)) //If its on someone, properly drop it
			var/mob/M = item_to_retrieve.loc

			if(issilicon(M) || !M.drop_item_ground(item_to_retrieve)) //Items in silicons warp the whole silicon
				var/turf/target_turf = get_turf(target)
				if(!target_turf)
					return

				M.visible_message(span_warning("[M] suddenly disappears!"), span_danger("A force suddenly pulls you away!"))
				M.forceMove(target_turf)
				M.loc.visible_message(span_caution("[M] suddenly appears!"))
				item_to_retrieve = null
				break

			if(ishuman(M)) //Edge case housekeeping
				var/mob/living/carbon/human/human = M
				if(human.remove_embedded_object(item_to_retrieve))
					to_chat(human, span_warning("The [item_to_retrieve] that was embedded into you has mysteriously vanished. How fortunate!"))

		else
			if(istype(item_to_retrieve.loc,/obj/machinery/portable_atmospherics/)) //Edge cases for moved machinery
				var/obj/machinery/portable_atmospherics/P = item_to_retrieve.loc
				P.disconnect()
				P.update_icon()
			if(is_type_in_typecache(item_to_retrieve.loc, blacklisted_summons))
				break
			item_to_retrieve = item_to_retrieve.loc
			if(ismodstorage(item_to_retrieve))
				var/obj/item/storage/backpack/modstorage/bag = item_to_retrieve
				if(bag.source && bag.source.mod)
					item_to_retrieve = bag.source.mod //Grab the modsuit.

		infinite_recursion += 1

	teleportate_item_to_target(item_to_retrieve, target)


/obj/effect/proc_holder/spell/summonitem/proc/teleportate_item_to_target(obj/item_to_retrieve, mob/living/target)
	if(!item_to_retrieve)
		return

	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return

	item_to_retrieve.loc.visible_message(span_warning("[DECLENT_RU_CAP(item_to_retrieve, NOMINATIVE)] неожиданно исчезает!"))
	playsound(target_turf, 'sound/magic/summonitems_generic.ogg', 50, TRUE)

	item_to_retrieve.forceMove(target_turf)

	if(target.put_in_active_hand(item_to_retrieve) || target.put_in_inactive_hand(item_to_retrieve))
		item_to_retrieve.loc.visible_message(span_caution("[DECLENT_RU_CAP(item_to_retrieve, NOMINATIVE)] внезапно появляется в руках [target.declent_ru(PREPOSITIONAL)]!"))
		return

	item_to_retrieve.loc.visible_message(span_caution("[DECLENT_RU_CAP(item_to_retrieve, NOMINATIVE)] внезапно появляется!"))
