#define TAB_ELECTRICITY "electricity"
#define TAB_ENGINES "engines"
#define TAB_FUEL "fuel"

#define NOT_SELECTED_RPM_PROVIDER "Не передавать"

/datum/ui_module/spacepod_control_panels
	name = "Панель управления космическим челноком"
	var/obj/spacepod2/pod
	var/selected_tab_id = TAB_ELECTRICITY

/datum/ui_module/spacepod_control_panels/ui_state(mob/user)
	if(isobserver(user))
		return ..()
	return GLOB.not_incapacitated_state

/datum/ui_module/spacepod_control_panels/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SpacepodControlPanel", name)
		ui.open()

/datum/ui_module/spacepod_control_panels/ui_data(mob/user)
	//create root data
	var/list/data = list()
	data["selected_tab"] = selected_tab_id
	data["tabs"] = create_tabs_data()
	data["electricity"] = create_electricity_panel_data()
	data["engines"] = create_engines_panel_data()
	data["fuel"] = create_fuel_panel_data()
	return data

/datum/ui_module/spacepod_control_panels/proc/create_tabs_data()
	var/tabs = list()
	tabs += list(list(
		"id" = TAB_ELECTRICITY,
		"name" = "Электропитание",
		"icon" = "bolt",
	))
	tabs += list(list(
		"id" = TAB_ENGINES,
		"name" = "Двигатели",
		"icon" = "gears",
	))
	tabs += list(list(
		"id" = TAB_FUEL,
		"name" = "Топливо",
		"icon" = "tint",
	))
	return tabs

/datum/ui_module/spacepod_control_panels/proc/create_electricity_panel_data()
	var panel = list()
	if(pod.systems.battery)
		panel["exists"] = TRUE
		panel["battery_id"] = pod.systems.battery.id
		panel["link"] = pod.systems.battery.connection_power_net
		panel["power"] = pod.systems.battery.power
		panel["capacity"] = pod.systems.battery.power_capacity
		panel["percent"] = round(pod.systems.battery.power / pod.systems.battery.power_capacity * 100, 1)
	else
		panel["exists"] = FALSE
	var/list/consumers = list()
	for(var/datum/spacepod_module/module in pod.systems.modules)
		if(module.consume_power > 0)
			var/list/consumer = list()
			consumer["id"] = module.id
			consumer["name"] = module.name
			consumer["link"] = module.connection_power_net
			consumers += list(consumer)
	panel["consumers"] = consumers
	return panel

/datum/ui_module/spacepod_control_panels/proc/create_engines_panel_data()
	var panel = list()
	var/list/engines = list()
	for(var/datum/spacepod_module/fuel_tank/engine/engine in pod.systems.engines)
		var/list/engine_data= list()
		engine_data["id"] = engine.id
		engine_data["name"] = engine.name
		engine_data["enable"] = engine.enable
		engine_data["rpm"] = engine.current_rpm
		engine_data["rpm_percent"] = round(engine.current_rpm / engine.max_rpm * 100, 1)
		engine_data["rpm_warn"] = engine_data["rpm_percent"] < 10 || engine_data["rpm_percent"] > 120
		engine_data["fuel_pressure"] = round(engine.fuel_amount / engine.fuel_capacity * 100, 1)
		engine_data["fuel_pressure_warn"] = engine_data["fuel_pressure"] <= 30
		if(istype(engine, /datum/spacepod_module/fuel_tank/engine/apu))
			var/datum/spacepod_module/fuel_tank/engine/apu/apu_engine = engine
			engine_data["power_link"] = apu_engine.connection_power_net
			engine_data["selected_rpm_provide_engine"] = apu_engine.rpm_destination_engine ? apu_engine.rpm_destination_engine.name : NOT_SELECTED_RPM_PROVIDER
			var/rpm_destinations = list()
			rpm_destinations += NOT_SELECTED_RPM_PROVIDER
			for(var/datum/spacepod_module/fuel_tank/engine/dest_engine in pod.systems.engines)
				if(engine == dest_engine)
					continue
				rpm_destinations += dest_engine.name
			engine_data["rpm_provide_engines"] = rpm_destinations
		else
			engine_data["power_link"] = null
			engine_data["rpm_provide_engines"] = null
		engine_data["generator_enable"] = engine.generator_enable
		engine_data["generated_power"] = engine.generator_enable ? round(engine.current_rpm / engine.max_rpm * engine.generate_power, 1) : 0
		engine_data["temperature"] = 32 + rand(1, 10)
		engine_data["temperature_warn"] = FALSE
		engine_data["error_text"] = engine.error_text
		engines += list(engine_data)
	panel["engines"] = engines
	// Gyroscope
	if(pod.systems.gyroscope)
		var/gyroscope_data = list()
		gyroscope_data["id"] = pod.systems.gyroscope.id
		gyroscope_data["name"] = pod.systems.gyroscope.name
		gyroscope_data["power_link"] = pod.systems.gyroscope.connection_power_net
		gyroscope_data["enable"] = pod.systems.gyroscope.enable
		gyroscope_data["rpm"] = pod.systems.gyroscope.current_rpm
		gyroscope_data["rpm_percent"] = round(pod.systems.gyroscope.current_rpm / pod.systems.gyroscope.max_rpm * 100, 1)
		gyroscope_data["rpm_warn"] = gyroscope_data["rpm_percent"] < 10 || gyroscope_data["rpm_percent"] > 120
		gyroscope_data["temperature"] = 32 + rand(1, 10)
		gyroscope_data["temperature_warn"] = FALSE
		gyroscope_data["error_text"] = pod.systems.gyroscope.error_text
		panel["gyroscope"] = gyroscope_data
	else
		panel["gyroscope"] = null
	return panel

/datum/ui_module/spacepod_control_panels/proc/create_fuel_panel_data()
	var panel = list()
	var/fuel_tanks = list()
	for(var/datum/spacepod_module/fuel_tank/fuel_tank in pod.systems.fuel_tanks)
		var/tank_data = list()
		tank_data["id"] = fuel_tank.id
		tank_data["name"] = fuel_tank.name
		tank_data["fuel_amount"] = fuel_tank.fuel_amount
		tank_data["fuel_capacity"] = fuel_tank.fuel_capacity
		tank_data["level_percent"] = round(fuel_tank.fuel_amount / fuel_tank.fuel_capacity * 100, 1)
		fuel_tanks += list(tank_data)
	panel["fuel_tanks"] = fuel_tanks
	var/fuel_pumps = list()
	for(var/datum/spacepod_module/fuel_pump/pump in pod.systems.fuel_pumps)
		var/pump_data = list()
		pump_data["id"] = pump.id
		pump_data["name"] = pump.name
		pump_data["enable"] = pump.enable
		pump_data["power_link"] = pump.connection_power_net
		pump_data["pump_speed"] = pump.enable ? pump.pump_speed : 0
		pump_data["temperature"] = 32 + rand(1, 10)
		pump_data["temperature_warn"] = FALSE
		pump_data["error_text"] = pump.error_text
		fuel_pumps += list(pump_data)
	panel["fuel_pumps"] = fuel_pumps
	return panel


// MARK: ui_act
/datum/ui_module/spacepod_control_panels/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = TRUE
	switch(action)
		if("select_tab")
			selected_tab_id = params["tab"]
		if("switch_powernet_link")
			var/id = params["id"]
			switch_powernet_link(id)
		if("switch_enable")
			var/id = params["id"]
			switch_enable(id)
		if("switch_generator_enable")
			var/id = params["id"]
			switch_generator_enable(id)
		if("select_rpm_provider")
			var/id = params["id"]
			var/dest_name = params["destination"]
			select_engine_rpm_provider(id, dest_name)
		else
			return ..()


/datum/ui_module/spacepod_control_panels/proc/switch_powernet_link(id)
	var/datum/spacepod_module/target_module = null
	for(var/datum/spacepod_module/module in pod.systems.modules)
		if(id == module.id)
			target_module = module
			break
	if(!target_module)
		return
	target_module.connection_power_net = !target_module.connection_power_net

/datum/ui_module/spacepod_control_panels/proc/switch_enable(id)
	var/datum/spacepod_module/target_module = null
	for(var/datum/spacepod_module/module in pod.systems.modules)
		if(id == module.id)
			target_module = module
			break
	if(!target_module)
		return
	if(target_module.enable)
		target_module.turn_off()
	else
		target_module.turn_on()

/datum/ui_module/spacepod_control_panels/proc/switch_generator_enable(id)
	var/datum/spacepod_module/fuel_tank/engine/target_engine = null
	for(var/datum/spacepod_module/fuel_tank/engine/engine in pod.systems.engines)
		if(id == engine.id)
			target_engine = engine
			break
	if(!target_engine)
		return
	if(!target_engine.generator_enable)
		target_engine.enable_power_generator()
	else
		target_engine.generator_enable = FALSE

/datum/ui_module/spacepod_control_panels/proc/select_engine_rpm_provider(id, destination_engine_name)
	var/datum/spacepod_module/fuel_tank/engine/apu/target_engine = null
	var/datum/spacepod_module/fuel_tank/engine/destination_engine = null
	for(var/datum/spacepod_module/fuel_tank/engine/engine in pod.systems.engines)
		if(id == engine.id && istype(engine, /datum/spacepod_module/fuel_tank/engine/apu))
			target_engine = engine
		if(destination_engine_name == engine.name)
			destination_engine = engine
	if(!target_engine)
		return
	if(destination_engine_name == NOT_SELECTED_RPM_PROVIDER || destination_engine == null)
		destination_engine = null
	target_engine.select_rpm_destination_engine(destination_engine)
