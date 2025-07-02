/datum/martial_art/krav_maga
	name = "Krav Maga"
	has_dirslash = FALSE
	weight = 9 //Higher weight, since you can choose to put on or take off the gloves
	var/datum/action/neck_chop/neckchop = new/datum/action/neck_chop()
	var/datum/action/leg_sweep/legsweep = new/datum/action/leg_sweep()
	var/datum/action/lung_punch/lungpunch = new/datum/action/lung_punch()
	var/datum/action/neutral_stance/neutral = new/datum/action/neutral_stance()

/datum/action/neutral_stance
	name = "Neutral Stance - You relax, cancelling your last Krav Maga stance attack."
	button_icon_state = "neutralstance"

/datum/action/neutral_stance/Trigger(left_click = TRUE, silence = FALSE)
	var/mob/living/carbon/human/H = owner
	if(!H.mind.martial_art.in_stance)
		if (!silence)
			to_chat(owner, "<b><i>You cannot cancel an attack you haven't prepared!</i></b>")
		return
	if (!silence)
		to_chat(owner, "<b><i>You cancel your prepared attack.</i></b>")
		owner.visible_message("<span class='danger'> [owner] relaxes [owner.p_their()] stance.</span>")
	H.mind.martial_art.combos.Cut()
	H.mind.martial_art.in_stance = FALSE

/datum/action/neck_chop
	name = "Neck Chop - Injures the neck, stopping the victim from speaking for a while."
	button_icon_state = "neckchop"

/datum/action/neck_chop/Trigger(left_click = TRUE, silence = FALSE)
	var/mob/living/carbon/human/H = owner
	if(!istype(H.mind.martial_art, /datum/martial_art/krav_maga))
		if (!silence)
			to_chat(owner, span_warning("You don't know how to do that right now."))
		return
	if(owner.incapacitated())
		if (!silence)
			to_chat(owner, "<span class='warning'>You can't use Krav Maga while you're incapacitated.</span>")
		return
	if (!silence)
		to_chat(owner, "<b><i>Your next attack will be a Neck Chop.</i></b>")
		owner.visible_message("<span class='danger'>[owner] assumes the Neck Chop stance!</span>")
	H.mind.martial_art.combos.Cut()
	H.mind.martial_art.combos.Add(/datum/martial_combo/krav_maga/neck_chop)
	H.mind.martial_art.reset_combos()
	H.mind.martial_art.in_stance = TRUE

/datum/action/leg_sweep
	name = "Leg Sweep - Trips the victim, rendering them prone and unable to move for a short time."
	button_icon_state = "legsweep"

/datum/action/leg_sweep/Trigger(left_click = TRUE, silence = FALSE)
	var/mob/living/carbon/human/H = owner
	if(!istype(H.mind.martial_art, /datum/martial_art/krav_maga))
		if (!silence)
			to_chat(owner, span_warning("You don't know how to do that right now."))
		return
	if(owner.incapacitated())
		if (!silence)
			to_chat(owner, "<span class='warning'>You can't use Krav Maga while you're incapacitated.</span>")
		return
	if (!silence)
		to_chat(owner, "<b><i>Your next attack will be a Leg Sweep.</i></b>")
		owner.visible_message("<span class='danger'>[owner] assumes the Leg Sweep stance!</span>")
	H.mind.martial_art.combos.Cut()
	H.mind.martial_art.combos.Add(/datum/martial_combo/krav_maga/leg_sweep)
	H.mind.martial_art.reset_combos()
	H.mind.martial_art.in_stance = TRUE

/datum/action/lung_punch//referred to internally as 'quick choke'
	name = "Lung Punch - Delivers a strong punch just above the victim's abdomen, constraining the lungs. The victim will be unable to breathe for a short time."
	button_icon_state = "lungpunch"

/datum/action/lung_punch/Trigger(left_click = TRUE, silence = FALSE)
	var/mob/living/carbon/human/H = owner
	if(!istype(H.mind.martial_art, /datum/martial_art/krav_maga))
		if (!silence)
			to_chat(owner, span_warning("You don't know how to do that right now."))
		return
	if(owner.incapacitated())
		if (!silence)
			to_chat(owner, "<span class='warning'>You can't use Krav Maga while you're incapacitated.</span>")
		return
	if (!silence)
		to_chat(owner, "<b><i>Your next attack will be a Lung Punch.</i></b>")
		owner.visible_message("<span class='danger'>[owner] assumes the Lung Punch stance!</span>")
	H.mind.martial_art.combos.Cut()
	H.mind.martial_art.combos.Add(/datum/martial_combo/krav_maga/lung_punch)
	H.mind.martial_art.reset_combos()
	H.mind.martial_art.in_stance = TRUE

/datum/martial_art/krav_maga/teach(var/mob/living/carbon/human/H,var/make_temporary=0, silence = FALSE)
	..()
	if(HAS_TRAIT(H, TRAIT_PACIFISM))
		if (!silence)
			to_chat(H, "<span class='warning'>The arts of Krav Maga echo uselessly in your head, the thought of their violence repulsive to you!</span>")
		return
	if (!silence)
		to_chat(H, "<span class = 'userdanger'>You know the arts of Krav Maga!</span>")
		to_chat(H, "<span class = 'danger'>Place your cursor over a move at the top of the screen to see what it does.</span>")
	neutral.Grant(H)
	neckchop.Grant(H)
	legsweep.Grant(H)
	lungpunch.Grant(H)

/datum/martial_art/krav_maga/remove(var/mob/living/carbon/human/H, silence = FALSE)
	..()
	if (!silence)
		to_chat(H, "<span class = 'userdanger'>You suddenly forget the arts of Krav Maga...</span>")
	neutral.Remove(H)
	neckchop.Remove(H)
	legsweep.Remove(H)
	lungpunch.Remove(H)

/datum/martial_art/krav_maga/harm_act(var/mob/living/carbon/human/A, var/mob/living/carbon/human/D)
	MARTIAL_ARTS_ACT_CHECK
	add_attack_logs(A, D, "Melee attacked with [src]")
	var/picked_hit_type = pick("punches", "kicks")
	var/bonus_damage = 10
	if(D.body_position == LYING_DOWN)
		bonus_damage += 5
		picked_hit_type = "stomps on"

	D.apply_damage(bonus_damage, BRUTE)
	objective_damage(A, D, bonus_damage, BRUTE)

	if(picked_hit_type == "kicks" || picked_hit_type == "stomps")
		A.do_attack_animation(D, ATTACK_EFFECT_KICK)
		playsound(get_turf(D), 'sound/effects/hit_kick.ogg', 50, 1, -1)
	else
		A.do_attack_animation(D, ATTACK_EFFECT_PUNCH)
		playsound(get_turf(D), 'sound/effects/hit_punch.ogg', 50, 1, -1)
	D.visible_message("<span class='danger'>[A] [picked_hit_type] [D]!</span>", \
					  "<span class='userdanger'>[A] [picked_hit_type] you!</span>")
	return TRUE

/datum/martial_art/krav_maga/disarm_act(var/mob/living/carbon/human/A, var/mob/living/carbon/human/D)
	MARTIAL_ARTS_ACT_CHECK
	if(prob(60))
		if(D.hand)
			if(isitem(D.l_hand))
				var/obj/item/I = D.l_hand
				if(D.drop_from_active_hand())
					A.put_in_hands(I, ignore_anim = FALSE)
		else
			if(isitem(D.r_hand))
				var/obj/item/I = D.r_hand
				if(D.drop_from_active_hand())
					A.put_in_hands(I, ignore_anim = FALSE)
		D.visible_message("<span class='danger'>[A] has disarmed [D]!</span>", \
							"<span class='userdanger'>[A] has disarmed [D]!</span>")
		playsound(D, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
	else
		D.visible_message("<span class='danger'>[A] attempted to disarm [D]!</span>", \
							"<span class='userdanger'>[A] attempted to disarm [D]!</span>")
		playsound(D, 'sound/weapons/punchmiss.ogg', 25, 1, -1)
	return TRUE

//Krav Maga Gloves

/obj/item/clothing/gloves/color/black/krav_maga
	var/datum/martial_art/krav_maga/style = new
	can_be_cut = FALSE
	resistance_flags = NONE

/obj/item/clothing/gloves/color/black/krav_maga/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(!ishuman(user) || slot != ITEM_SLOT_GLOVES)
		return .
	style.teach(user, TRUE)


/obj/item/clothing/gloves/color/black/krav_maga/dropped(mob/user, slot, silent = FALSE)
	. = ..()
	if(!ishuman(user) || slot != ITEM_SLOT_GLOVES)
		return .
	style.remove(user)


/obj/item/clothing/gloves/color/black/krav_maga/sec//more obviously named, given to sec
	name = "krav maga gloves"
	desc = "These gloves can teach you to perform Krav Maga using nanochips."
	icon_state = "fightgloves"
	item_state = "fightgloves"

/obj/item/clothing/gloves/color/black/krav_maga/sec/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/high_value_item)

/obj/item/clothing/gloves/color/black/krav_maga/emp_act(severity)
	. = ..()
	if(!ishuman(loc))
		return
	var/mob/living/carbon/human/user = loc
	if (prob(20))
		to_chat(user, span_danger("The [src] buzzes!"))
		style.remove(user, silence = TRUE)
		var/duration = rand(2, 5)
		addtimer(CALLBACK(src, PROC_REF(restore_from_emp)), duration SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_DELETE_ME)
		return
	switch(rand(1,100))
		if(1 to 20)
			to_chat(user, span_danger("You feel electricity burning through your hands inside the [src]."))
			user.apply_damage(rand(2, 5), BURN, def_zone = BODY_ZONE_PRECISE_R_HAND)
			user.apply_damage(rand(2, 5), BURN, def_zone = BODY_ZONE_PRECISE_L_HAND)
		if (21 to 40) // Random action
			switch(rand(1, 3))
				if (1)
					style.lungpunch.Trigger(silence = TRUE)
				if (2)
					style.legsweep.Trigger(silence = TRUE)
				if (3)
					style.neckchop.Trigger(silence = TRUE)
		if (41 to 80) // Cancel prepared action
			if (user.mind && user.mind.martial_art.in_stance)
				style.neutral.Trigger(silence = TRUE)
		if (81 to 100)
			to_chat(user, span_danger("Your [src] sparks and uses a move on you."))
			if (user.mind && user.mind.martial_art.in_stance)
				style.harm_act(user, user)

/obj/item/clothing/gloves/color/black/krav_maga/proc/restore_from_emp()
	var/mob/living/carbon/human/user = loc
	style.teach(user, TRUE, silence = TRUE)
