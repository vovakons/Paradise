/// Basic action for pod actions
/datum/action/innate/pod_action
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_CONSCIOUS|AB_CHECK_INCAPACITATED
	button_icon = 'icons/mob/actions/actions_mecha.dmi'
	var/obj/pod/pod

/datum/action/innate/pod_action/Grant(mob/living/user, obj/pod/target)
	if(target)
		pod = target
	. = ..()

/datum/action/innate/pod_action/Destroy()
	pod = null
	return ..()

/datum/action/innate/pod_action/pod_eject
	name = "Выйти из челнока"
	button_icon_state = "mech_eject"

/datum/action/innate/pod_action/pod_eject/Activate()
	pod.exit_pod(owner)


/datum/action/innate/pod_action/pod_direction_lock
	name = "Переключить движение боком"
	button_icon_state = "strafe"

/datum/action/innate/pod_action/pod_direction_lock/Activate()
	pod.lock_facing_direction = !pod.lock_facing_direction
