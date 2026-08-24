#define POD_MODULE_FIRE_DAMAGE 5
#define POD_MODULE_HIT_CHANCE_SMALL 5
#define POD_MODULE_HIT_CHANCE_NORMAL 10
#define POD_MODULE_HIT_CHANCE_LARGE 20
#define POD_MODULE_HIT_CHANCE_EXTRA_LARGE 40

// MARK: Spacepod systems
/datum/spacepod_systems
	var/list/datum/spacepod_module/modules = list()
	var/datum/spacepod_module/battery/battery = null
	var/list/datum/spacepod_module/fuel_tank/fuel_tanks = list()
	var/list/datum/spacepod_module/fuel_pump/fuel_pumps = list()
	var/datum/spacepod_module/fuel_tank/engine/apu/apu = null
	var/list/datum/spacepod_module/fuel_tank/engine/engines = list()
	var/datum/spacepod_module/gyroscope/gyroscope = null
	var/datum/spacepod_module/weapon/weapon = null

/datum/spacepod_systems/Destroy(force)
	. = ..()
	battery = null
	fuel_tanks = null
	fuel_pumps = null
	apu = null
	engines = null
	gyroscope = null
	QDEL_LIST(modules)

/datum/spacepod_systems/proc/check_complete()
	. = list()
	if(battery == null)
		. += span_notice("Отсутствует аккумуляторная батарея.")
	if(fuel_tanks == null || length(fuel_tanks) == 0)
		. += span_notice("Отсутствуют топливные баки.")
	if(fuel_pumps == null || length(fuel_pumps) == 0)
		. += span_notice("Отсутствуют топливные насосы.")
	var/exists_engine = FALSE
	if(engines)
		for(var/datum/spacepod_module/fuel_tank/engine/engine in engines)
			if(!engine.is_apu())
				exists_engine = TRUE
				break
	if(!exists_engine)
		. += span_notice("Отсутствуют двигатели.")
	if(apu == null)
		. += span_notice("Отсутствует вспомогательная силовая установка.")
	if(gyroscope == null)
		. += span_notice("Отсутствует гироскопический стабилизатор.")

/datum/spacepod_systems/proc/add_module(datum/spacepod_module/module)
	module.systems = src
	modules += module
	if(istype(module, /datum/spacepod_module/battery))
		battery = module
	if(istype(module, /datum/spacepod_module/fuel_pump))
		fuel_pumps += module
	if(istype(module, /datum/spacepod_module/fuel_tank/engine/apu))
		apu = module
		engines += module
	else if(istype(module, /datum/spacepod_module/fuel_tank/engine))
		engines += module
	else if(istype(module, /datum/spacepod_module/fuel_tank))
		fuel_tanks += module
	if(istype(module, /datum/spacepod_module/gyroscope))
		gyroscope = module
	if(istype(module, /datum/spacepod_module/weapon))
		weapon = module

/datum/spacepod_systems/proc/remove_module(datum/spacepod_module/module)
	module.enable = FALSE
	module.fire = FALSE
	module.connection_power_net = FALSE
	module.systems = null
	modules -= module
	if(istype(module, /datum/spacepod_module/battery))
		battery = null
	if(istype(module, /datum/spacepod_module/fuel_pump))
		fuel_pumps -= module
	if(istype(module, /datum/spacepod_module/fuel_tank/engine/apu))
		remove_fuel_tank_from_pumps(module)
		apu.select_rpm_destination_engine(null)
		apu = null
		engines -= module
	else if(istype(module, /datum/spacepod_module/fuel_tank/engine))
		remove_fuel_tank_from_pumps(module)
		engines -= module
	else if(istype(module, /datum/spacepod_module/fuel_tank))
		remove_fuel_tank_from_pumps(module)
		fuel_tanks -= module
	if(istype(module, /datum/spacepod_module/gyroscope))
		gyroscope = null
	if(istype(module, /datum/spacepod_module/weapon))
		weapon = null

/datum/spacepod_systems/proc/remove_fuel_tank_from_pumps(datum/spacepod_module/fuel_tank/tank)
	for(var/datum/spacepod_module/fuel_pump/pump in fuel_pumps)
		if(pump.source_tank == tank)
			pump.source_tank = null
		if(pump.destination_tank == tank)
			pump.destination_tank = null

/datum/spacepod_systems/proc/process_work(seconds_per_tick, obj/spacepod2/pod)
	for(var/datum/spacepod_module/module as anything in modules)
		if(module.fire)
			module.fire_process()
		module.process_work(seconds_per_tick)

/datum/spacepod_systems/proc/get_total_speed_mod()
	if(!length(engines))
		return 0
	var/total_thrust = 0
	var/max_thrust = 0
	for(var/datum/spacepod_module/fuel_tank/engine/engine as anything in engines)
		if(engine.is_apu())
			continue
		total_thrust += engine.current_rpm / engine.max_rpm
		max_thrust += 1
	if(max_thrust == 0) //zero div check
		max_thrust = 1
	return clamp(total_thrust / max_thrust, 0, 1)

/datum/spacepod_systems/proc/can_maneuver()
	if(!gyroscope)
		return FALSE
	return gyroscope.is_working()


// MARK: Basic module
/datum/spacepod_module
	var/id = "unknown"
	var/name = "Модуль челнока"
	var/datum/spacepod_systems/systems = null

	/// Current module integrity
	var/integrity
	/// Maximal module integrity
	var/max_integrity = 100
	/// Hit chance weight
	var/hit_weight = POD_MODULE_HIT_CHANCE_NORMAL
	/// Enable status flag
	var/enable = FALSE
	/// Fire process
	var/fire = FALSE
	/// Module fire damage multiplyer
	var/fire_damage_mod = 1
	/// Connect to electric power net
	var/connection_power_net = FALSE
	/// Amount of consumed power in watt per tick
	var/consume_power = 0
	/// Error detail data
	var/error_text = null
	/// Linked module item
	var/obj/item/spacepod_module/module_item = null

/datum/spacepod_module/New(id)
	. = ..()
	src.id = id
	integrity = max_integrity

/datum/spacepod_module/proc/fire_process()
	if(!fire)
		return FALSE
	if(integrity == 0)
		return FALSE

	integrity -= POD_MODULE_FIRE_DAMAGE * fire_damage_mod
	if(integrity < 0)
		integrity = 0

	return integrity > 0

/datum/spacepod_module/proc/process_power(seconds_per_tick)
	if(!connection_power_net)
		return FALSE
	if(!systems || !systems.battery)
		return FALSE
	return systems.battery.consume_power(consume_power * seconds_per_tick)

/datum/spacepod_module/proc/process_work(seconds_per_tick)
	return enable

/datum/spacepod_module/proc/turn_on()
	error_text = null
	enable = TRUE

/datum/spacepod_module/proc/turn_off()
	enable = FALSE


// MARK: Fuel tank
/*
Engine consume 2 unit fuel per tick
One engine spacepod:
	Basic fuel tank can contain 1000 unit - 8.33 minutes of flight
	Three basic fuel tanks contain 3000 units - 25 minutes of flight
	Large fuel tank contain 2000 unit - 16.66 minutes of flight
	Three basic fuel tanks contain 6000 units - 50 minutes of flight
Two engine spacepod:
	Basic fuel tank can contain 1000 unit - 4.16 minutes of flight
	Three basic fuel tanks contain 3000 units - 12.5 minutes of flight
	Large fuel tank contain 2000 unit - 8.33 minutes of flight
	Three basic fuel tanks contain 6000 units - 25 minutes of flight
Three engine spacepod:
	Basic fuel tank can contain 1000 unit - 2.77 minutes of flight
	Three basic fuel tanks contain 3000 units - 8.33 minutes of flight
	Large fuel tank contain 2000 unit - 5.55 minutes of flight
	Three basic fuel tanks contain 6000 units - 16.66 minutes of flight
*/
/datum/spacepod_module/fuel_tank
	name = "Топливный бак"
	max_integrity = 200
	hit_weight = POD_MODULE_HIT_CHANCE_LARGE
	fire_damage_mod = 2
	/// Fuel capacity in units
	var/fuel_capacity = 1000 //units
	/// Current fuel level in units
	var/fuel_amount = 0

/datum/spacepod_module/fuel_tank/proc/consume_fuel(amount)
	if(amount > fuel_amount)
		amount = fuel_amount

	fuel_amount -= amount
	return amount

/datum/spacepod_module/fuel_tank/full/New(id)
	. = ..()
	fuel_amount = fuel_capacity

/datum/spacepod_module/fuel_tank/large
	name = "Большой топливный бак"
	max_integrity = 300
	hit_weight = POD_MODULE_HIT_CHANCE_EXTRA_LARGE
	fuel_capacity = 2000

/datum/spacepod_module/fuel_tank/large/full/New(id)
	. = ..()
	fuel_amount = fuel_capacity


// MARK: Battery
/datum/spacepod_module/battery
	name = "Аккумуляторная батарея"
	max_integrity = 200
	enable = TRUE
	/// Battery capacity in watt
	var/power_capacity = 5000 //watt
	/// Current power level in watt
	var/power = 0

/datum/spacepod_module/battery/full/New(id)
	. = ..()
	power = power_capacity

/datum/spacepod_module/battery/proc/consume_power(amount)
	if(!connection_power_net)
		return FALSE
	if(!enable)
		return FALSE
	if(power < amount)
		return FALSE
	power -= amount
	return TRUE

/datum/spacepod_module/battery/proc/accumulate_power(amount)
	power = min(power + amount, power_capacity)


// MARK: Fuel pump
/datum/spacepod_module/fuel_pump
	name = "Топливный насос"
	max_integrity = 50
	hit_weight = POD_MODULE_HIT_CHANCE_SMALL
	fire_damage_mod = 5
	consume_power = 10
	/// Fuel pumping speed in units per tick
	var/pump_speed = 10 //units per tick
	var/datum/spacepod_module/fuel_tank/source_tank
	var/datum/spacepod_module/fuel_tank/destination_tank

/datum/spacepod_module/fuel_pump/process_work(seconds_per_tick)
	. = ..()
	if(!.)
		return
	if(source_tank == null || destination_tank == null)
		error_text = "Отсутствует подключение!"
		turn_off()
		return
	if(!process_power(seconds_per_tick))
		if(!connection_power_net)
			error_text = "Нет подключения к электросети для работы топливного насоса"
		else
			error_text = "Не хватает электричества для работы топливного насоса"
		turn_off()
		return
	var/pumped = pump_speed * seconds_per_tick
	if(pumped > source_tank.fuel_amount)
		pumped = source_tank.fuel_amount
	var/free_space = max(destination_tank.fuel_capacity - destination_tank.fuel_amount, 0)
	if(pumped > free_space)
		pumped = free_space
	if(pumped <= 0)
		return
	source_tank.fuel_amount -= pumped
	destination_tank.fuel_amount += pumped


// MARK: Engines
/datum/spacepod_module/fuel_tank/engine
	name = "Двигатель"
	hit_weight = POD_MODULE_HIT_CHANCE_LARGE
	max_integrity = 300
	fire_damage_mod = 1
	fuel_capacity = 30
	/// How many fuel consume in units per tick on 100% of power
	var/fuel_consume_amount = 2
	/// Maximal rotations per minutes
	var/max_rpm = 15000
	/// Current rotations per minutes
	var/current_rpm = 0
	/// Ignition acceleration (rpm increase per units)
	var/ignition_acceleration = 1000
	/// How many fuel consume in units per seconds
	var/fuel_consume_speed = 2 // unit/sec
	var/generator_enable = FALSE
	/// How many powers generate on 100% rpm per seconds in watt
	var/generate_power = 100
	/// Receiving external rotation
	var/external_rotation = FALSE

/datum/spacepod_module/fuel_tank/engine/proc/get_rpm_percent()
	return round(current_rpm / max_rpm * 100, 1)

/datum/spacepod_module/fuel_tank/engine/turn_on()
	error_text = null
	ignite()

/datum/spacepod_module/fuel_tank/engine/proc/ignite()
	if(enable)
		return FALSE
	if(current_rpm <= 0) //no rotation - no ignition, provde rotations from apu
		error_text = "Нет оборотов для запуска"
		return FALSE
	enable = TRUE
	external_rotation = FALSE
	return TRUE

/datum/spacepod_module/fuel_tank/engine/proc/enable_power_generator()
	if(current_rpm > 0)
		generator_enable = TRUE
	else
		error_text = "Нет оборотов двигателя для запуска генератора"

/datum/spacepod_module/fuel_tank/engine/proc/is_apu()
	return FALSE

/datum/spacepod_module/fuel_tank/engine/process_work(seconds_per_tick)
	if(generator_enable)
		var/rpm_mod = current_rpm / max_rpm
		if(systems && systems.battery)
			systems.battery.accumulate_power(rpm_mod * generate_power * seconds_per_tick)

	if(!enable) // slowly stoping
		if(external_rotation || current_rpm == 0)
			return
		current_rpm = max(current_rpm - ignition_acceleration * seconds_per_tick, 0)
		return

	if(!consume_fuel(fuel_consume_speed * seconds_per_tick) > 0)
		error_text = "Топливное голодание"
		enable = FALSE //auto off
		return
	if(current_rpm >= max_rpm)
		return
	current_rpm = min(current_rpm + ignition_acceleration * seconds_per_tick, max_rpm)

// MARK: APU
/datum/spacepod_module/fuel_tank/engine/apu
	name = "Вспомогательная силовая установка"
	consume_power = 1000
	generate_power = 50
	var/datum/spacepod_module/fuel_tank/engine/rpm_destination_engine = null

/datum/spacepod_module/fuel_tank/engine/apu/is_apu()
	return TRUE

/datum/spacepod_module/fuel_tank/engine/apu/ignite()
	if(enable || current_rpm > 0)
		return FALSE
	if(!process_power(1)) // can not ignite, because low power
		if(!connection_power_net)
			error_text = "Нет подключения к электросети для запуска стартера"
		else
			error_text = "Не хватает электричества для запуска стартера"
		return FALSE
	enable = TRUE
	return TRUE

/datum/spacepod_module/fuel_tank/engine/apu/turn_off()
	. = ..()
	if(rpm_destination_engine != null)
		select_rpm_destination_engine(null)

/datum/spacepod_module/fuel_tank/engine/apu/process_work(seconds_per_tick)
	. = ..()
	if(current_rpm <= 0 || !rpm_destination_engine)
		return
	if(!enable)
		select_rpm_destination_engine(null)
		return
	rpm_destination_engine.current_rpm = max(rpm_destination_engine.current_rpm, current_rpm / 10) // 10% of rpm provde to engine for ignition
	current_rpm = max(current_rpm - current_rpm / 20, 0) // slowly stop by 5% becase rpm provide to engine
	if(current_rpm == 0)
		error_text = "Низкие обороты"
		turn_off()

/datum/spacepod_module/fuel_tank/engine/apu/proc/select_rpm_destination_engine(datum/spacepod_module/fuel_tank/engine/destination)
	if(!enable && destination)
		return
	if(rpm_destination_engine)
		rpm_destination_engine.external_rotation = FALSE
	rpm_destination_engine = destination
	if(rpm_destination_engine)
		rpm_destination_engine.external_rotation = TRUE


// MARK: Gyroscope
/datum/spacepod_module/gyroscope
	name = "Гироскопический стабилизатор"
	hit_weight = POD_MODULE_HIT_CHANCE_LARGE
	max_integrity = 250
	consume_power = 50
	/// Maximal rotations per minutes
	var/max_rpm = 50000
	/// Current rotations per minutes
	var/current_rpm = 0
	/// Ignition acceleration (rpm increase per units)
	var/ignition_acceleration = 1000

/datum/spacepod_module/gyroscope/process_work(seconds_per_tick)
	if(!enable) // slowly stoping
		if(current_rpm == 0)
			return
		current_rpm = max(current_rpm - ignition_acceleration * seconds_per_tick, 0)
		return
	if(!process_power(seconds_per_tick))
		if(!connection_power_net)
			error_text = "Нет подключения к электросети для работы гироскопического стабилизатора"
		else
			error_text = "Не хватает электричества для работы гироскопического стабилизатора"
		turn_off()
		return
	if(current_rpm >= max_rpm)
		return
	current_rpm = min(current_rpm + ignition_acceleration * seconds_per_tick, max_rpm)

/datum/spacepod_module/gyroscope/proc/is_working()
	return current_rpm > max_rpm / 2


// MARK: Weapon
/datum/spacepod_module/weapon
	name = "Модуль вооружения"
	hit_weight = POD_MODULE_HIT_CHANCE_LARGE
	max_integrity = 250
	consume_power = 5
	var/only_course_fire = FALSE
	var/datum/spacepod_weapon_slot/primary = new("primary", "Основное")
	var/datum/spacepod_weapon_slot/secondary = new("secondary", "Дополнительное")

/datum/spacepod_module/weapon/Destroy(force)
	QDEL_NULL(primary)
	QDEL_NULL(secondary)
	. = ..()

/datum/spacepod_module/weapon/proc/install_gun(obj/item/gun/installed_gun)
	if(primary.weapon == null)
		primary.weapon = installed_gun
		return TRUE
	if(secondary.weapon == null)
		secondary.weapon = installed_gun
		return TRUE
	return FALSE

/datum/spacepod_module/weapon/proc/remove_gun(obj/item/gun/selected_gun)
	if(primary.weapon == selected_gun)
		primary.weapon = null
		primary.charging = FALSE
		primary.safety = TRUE
		return selected_gun
	if(secondary.weapon == selected_gun)
		secondary.weapon = null
		secondary.charging = FALSE
		secondary.safety = TRUE
		return selected_gun
	return null


/datum/spacepod_weapon_slot
	var/id
	var/name
	var/obj/item/gun/weapon = null
	var/safety = TRUE
	var/charging = FALSE
	var/recharge_rate = 100

/datum/spacepod_weapon_slot/New(id, name)
	. = ..()
	src.id = id
	src.name = name

/datum/spacepod_weapon_slot/proc/reload(obj/spacepod2/pod, mob/user)
	if(weapon == null)
		return
	if(isenergygun(weapon))
		charging = !charging
		return

	if(isprojectilegun(weapon))
		var/obj/item/gun/projectile/gun = weapon
		for(var/obj/item/ammo_box/magazine/magazine in pod.cargo_hold.contents)
			if(!istype(magazine, gun.mag_type))
				continue
			var/obj/item/ammo_box/magazine/gun_magazine = gun.magazine
			gun.attackby(magazine, user)
			var/mag_changed = (gun_magazine && gun_magazine.loc != gun)
			if(!mag_changed || !pod.cargo_hold.can_be_inserted(gun_magazine))
				return
			pod.cargo_hold.handle_item_insertion(gun_magazine)
			gun_magazine.update_appearance()
			return

/datum/spacepod_weapon_slot/proc/process_charge(datum/spacepod_module/weapon/module)
	if(weapon == null)
		return
	if(!charging)
		return
	if(!isenergygun(weapon))
		return
	var/obj/item/gun/energy/energy_gun = weapon
	if(module.systems.battery.consume_power(recharge_rate))
		energy_gun.cell.give(recharge_rate)

/datum/spacepod_module/weapon/process_work(seconds_per_tick)
	if(!enable)
		return
	if(!process_power(seconds_per_tick))
		if(!connection_power_net)
			error_text = "Нет подключения к электросети"
		else
			error_text = "Не хватает электричества для работы"
		turn_off()
		return
	primary.process_charge(src)
	secondary.process_charge(src)


/datum/spacepod_module/weapon/course
	name = "Модуль курсового вооружения"
	only_course_fire = TRUE

/datum/spacepod_module/weapon/turret
	name = "Модуль турельного вооружения"
