import { useBackend } from '../backend';
import { Tabs, Box, Section, Button, Table, Dropdown, Flex, Stack } from '../components';
import { Window } from '../layouts';
import { ComplexModal } from './common/ComplexModal';

type SpacepodControlPanelData = {
  selected_tab: string;
  tabs: SpacepodControlPanelTabsData[];
  electricity: ElectricityPanelData;
  engines: EnginesPanelData;
  fuel: FuelSystemPanelData;
  weapons: WeaponsPanelData;
  life_support: LifeSupportPanelData;
};

type SpacepodControlPanelTabsData = {
  id: string;
  name: string;
  icon: string;
};

const decideTab = (tab_id: string) => {
  switch (tab_id) {
    case 'electricity':
      return <ElectricityPanel />;
    case 'engines':
      return <EnginesPanel />;
    case 'fuel':
      return <FuelSystemPanel />;
    case 'life_support':
      return <LifeSupportPanel />;
    case 'weapons':
      return <WeaponsPanel />;
    default:
      return (
        <Section>
          <h2>НЕИЗВЕТНАЯ ОШИБКА!</h2>
          <b>Перезагрузите авионику космического челнока.</b>
        </Section>
      );
  }
};

// MARK: Window
export const SpacepodControlPanel = (props: unknown) => {
  const { act, data } = useBackend<SpacepodControlPanelData>();
  const { selected_tab, tabs } = data;

  return (
    <Window width={500} height={600} title="Панель управления космическим челноком">
      <ComplexModal />
      <Window.Content scrollable>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs fluid>
              {tabs.map((tab) => (
                <Tabs.Tab
                  key={tab.id}
                  icon={tab.icon}
                  selected={tab.id === selected_tab}
                  onClick={() => act('select_tab', { tab: tab.id })}
                >
                  {tab.name}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          {decideTab(selected_tab)}
        </Stack>
      </Window.Content>
    </Window>
  );
}


// MARK: Electricity panel
type ElectricityPanelData = {
  exists: boolean;
  link: boolean;
  battery_id: string;
  power: string;
  capacity: string;
  percent: string;
  consumers: ElectricityConsumerData[];
};

type ElectricityConsumerData = {
  id: string;
  name: string;
  link: boolean;
};

const ElectricityPanel = (props: unknown) => {
  const { act, data } = useBackend<SpacepodControlPanelData>();
  const { electricity } = data;

  return (
    <Stack vertical fill>
      {/* Battery section */}
      <Stack.Item>
        {electricity.exists ? (
          <Section title="Аккумуляторная батарея" ml='0' mr='0'>
            <Table>
              <ToggleButtonRow
                caption='Соединение к электросети'
                enable={electricity.link}
                enable_text='Подключено'
                disable_text='Отключено'
                clicked={() => act('switch_powernet_link', { id: electricity.battery_id })}
              />
              <TextRow
                caption='Заряд батареи'
                value_text={electricity.power + ' Вт'}
              />
              <TextRow
                caption='Емкость аккумулятора'
                value_text={electricity.capacity + ' Вт·ч'}
              />
              <TextRow
                caption='Заряд в процентах'
                value_text={electricity.percent + '%'}
              />
            </Table>
          </Section>
        ) : (
          <Box><b>Аккумуляторная батаерея отсутствует!</b></Box>
        )}
      </Stack.Item>
      {/* Electricity consumers section */}
      <Stack.Item grow>
        <Section fill scrollable title="Потребители">
            <Table>
                {electricity.consumers.map(consumer => (
                    <ToggleButtonRow
                      key={consumer.id}
                      caption={consumer.name}
                      enable={consumer.link}
                      enable_text='Подключено'
                      disable_text='Отключено'
                      clicked={() => act('switch_powernet_link', { id: consumer.id })}
                    />
                ))}
            </Table>
        </Section>
      </Stack.Item>
    </Stack>
  );
};


// MARK: Engines panel
type EnginesPanelData = {
  engines: EngineData[];
  gyroscope: GyroscopeData;
};

type EngineData = {
  id: string;
  name: string;
  power_link: boolean;
  enable: boolean;
  rpm: number;
  rpm_percent: number;
  rpm_warn: boolean;
  fuel_pressure: number;
  fuel_pressure_warn: boolean;
  rpm_provide_engines: string[];
  selected_rpm_provide_engine: string;
  generator_enable: boolean;
  generated_power: number;
  temperature: number;
  temperature_warn: boolean;
  error_text: string;
};

type GyroscopeData = {
  id: string;
  name: string;
  power_link: boolean;
  enable: boolean;
  rpm: number;
  rpm_percent: number;
  rpm_warn: boolean;
  temperature: number;
  temperature_warn: boolean;
  error_text: string;
};

const EnginesPanel = (props: unknown) => {
  const { act, data } = useBackend<SpacepodControlPanelData>();
  const { engines } = data;

  return (
    <Stack vertical fill>
      {engines.engines.map(engine => (
        <Stack.Item key={engine.id}>
          <Section title={engine.name} ml='0' mr='0'>
            <Table>
              {engine.power_link !== null ? (
                <TextStatusRow
                  caption='Соединение к электросети'
                  enable={engine.power_link}
                  enable_text='Подключено'
                  disable_text='Отключено'
                />
              ) : ('')}
              <ToggleButtonRow
                caption='Состояние'
                enable={engine.enable}
                enable_text='Запущено'
                disable_text='Отключено'
                clicked={() => act('switch_enable', { id: engine.id })}
              />
              <ColorTextRow
                caption='Обороты'
                value_text={engine.rpm + ' RPM'}
                warn={engine.rpm_warn}
              />
              <ColorTextRow
                caption='Мощность'
                value_text={engine.rpm_percent + '%'}
                warn={engine.rpm_warn}
              />
              <ColorTextRow
                caption='Давление топлива'
                value_text={engine.fuel_pressure + '%'}
                warn={engine.fuel_pressure_warn}
              />
              {engine.rpm_provide_engines !== null ? (
                <Table.Row>
                  <Table.Cell bold width='50%'>Передача крутящего момента:</Table.Cell>
                  <Box pb={1}>
                    <Dropdown
                      options={engine.rpm_provide_engines}
                      selected={engine.selected_rpm_provide_engine}
                      onSelected={(value) => act('select_rpm_provider', {
                          id: engine.id,
                          destination: value
                      })}
                    />
                  </Box>
                </Table.Row>
              ) : ('')}
              <ToggleButtonRow
                caption='Генератор'
                enable={engine.generator_enable}
                enable_text='Запущено'
                disable_text='Отключено'
                clicked={() => act('switch_generator_enable', { id: engine.id })}
              />
              <TextRow
                caption='Генерация электричества'
                value_text={engine.generated_power + ' ватт'}
              />
              <ColorTextRow
                caption='Температура'
                value_text={engine.temperature + ' C'}
                warn={engine.temperature_warn}
              />
              <ErrorRow error_text={engine.error_text} />
            </Table>
          </Section>
        </Stack.Item>
      ))}
      {engines.gyroscope !== null ? (
        <Stack.Item>
          <Section title={engines.gyroscope.name} ml='0' mr='0'>
            <Table>
              <TextStatusRow
                caption='Соединение к электросети'
                enable={engines.gyroscope.power_link}
                enable_text='Подключено'
                disable_text='Отключено'
              />
              <ToggleButtonRow
                caption='Состояние'
                enable={engines.gyroscope.enable}
                enable_text='Запущено'
                disable_text='Отключено'
                clicked={() => act('switch_enable', { id: engines.gyroscope.id })}
              />
              <ColorTextRow
                caption='Обороты'
                value_text={engines.gyroscope.rpm + ' RPM'}
                warn={engines.gyroscope.rpm_warn}
              />
              <ColorTextRow
                caption='Мощность'
                value_text={engines.gyroscope.rpm_percent + '%'}
                warn={engines.gyroscope.rpm_warn}
              />
              <ColorTextRow
                caption='Температура'
                value_text={engines.gyroscope.temperature + ' C'}
                warn={engines.gyroscope.temperature_warn}
              />
              <ErrorRow error_text={engines.gyroscope.error_text} />
            </Table>
          </Section>
        </Stack.Item>
      ) : ('')}
    </Stack>
  );
};



// MARK: Fuel system panel
type FuelSystemPanelData = {
  fuel_tanks: FuelTankData[];
  fuel_pumps: FuelPumpData[];
};

type FuelTankData = {
  id: string;
  name: string;
  fuel_amount: number;
  fuel_capacity: number;
  level_percent: number;
};

type FuelPumpData = {
  id: string;
  name: string;
  power_link: boolean;
  enable: boolean;
  pump_speed: number;
  temperature: number;
  temperature_warn: boolean;
  error_text: string;
};

const FuelSystemPanel = (props: unknown) => {
  const { act, data } = useBackend<SpacepodControlPanelData>();
  const { fuel } = data;

  return (
    <Stack vertical fill>
      {/* Fuel tanks section */}
      {fuel.fuel_tanks.map(fuel_tank => (
        <Stack.Item key={fuel_tank.id}>
          <Section title={fuel_tank.name} ml='0' mr='0'>
            <Table>
              <TextRow
                caption='Емкость топлива'
                value_text={fuel_tank.fuel_capacity + ' л.'}
              />
              <ColorTextRow
                caption='Уровень топлива'
                value_text={fuel_tank.fuel_amount + ' л.'}
                warn={fuel_tank.level_percent < 20}
              />
              <ColorTextRow
                caption='Уровень в процентах'
                value_text={fuel_tank.level_percent + '%'}
                warn={fuel_tank.level_percent < 20}
              />
            </Table>
          </Section>
        </Stack.Item>
      ))}
      {/* Fuel pumps section */}
      {fuel.fuel_pumps.map(fuel_pump => (
        <Stack.Item key={fuel_pump.id}>
          <Section title={fuel_pump.name} ml='0' mr='0'>
            <Table>
              <TextStatusRow
                caption='Соединение к электросети'
                enable={fuel_pump.power_link}
                enable_text='Подключено'
                disable_text='Отключено'
              />
              <ToggleButtonRow
                caption='Состояние'
                enable={fuel_pump.enable}
                enable_text='Запущено'
                disable_text='Отключено'
                clicked={() => act('switch_enable', { id: fuel_pump.id })}
              />
              <TextRow
                caption='Скорость перекачки'
                value_text={fuel_pump.pump_speed + ' литр/сек'}
              />
              <ColorTextRow
                caption='Температура'
                value_text={fuel_pump.temperature + ' C'}
                warn={fuel_pump.temperature_warn}
              />
              <ErrorRow error_text={fuel_pump.error_text} />
            </Table>
          </Section>
        </Stack.Item>
      ))}
    </Stack>
  );
};


// MARK: Weapons panel
type WeaponsPanelData = {
  module: WeaponModuleData;
  guns: GunData[];
};


type WeaponModuleData = {
  id: string;
  name: string;
  enable: boolean;
  power_link: boolean;
  error_text: string;
};

type GunData = {
  id: string;
  name: string;
  primary: boolean;
  safety: boolean;
  type: number;
  ammo: number;
  capacity: number;
  charging: boolean;
};

const get_gun_type_name = (type: number) => {
  switch(type) {
    case 1:
      return "Баллистический"
    case 2:
      return "Энергетический"
    case 0:
      return "Неизвестно"
  }
};

const WeaponsPanel = (props: unknown) => {
  const { act, data } = useBackend<SpacepodControlPanelData>();
  const { weapons } = data;

  return (
    <Stack vertical fill>
      {/* Module section */}
      {weapons.module === null ? ('') : (
        <Stack.Item>
          <Section title={weapons.module.name} ml='0' mr='0'>
            <Table>
              <TextStatusRow
                caption='Соединение к электросети'
                enable={weapons.module.power_link}
                enable_text='Подключено'
                disable_text='Отключено'
              />
              <ToggleButtonRow
                caption='Состояние'
                enable={weapons.module.enable}
                enable_text='Запущено'
                disable_text='Отключено'
                clicked={() => act('switch_enable', { id: weapons.module.id })}
              />
              <ErrorRow error_text={weapons.module.error_text} />
            </Table>
          </Section>
        </Stack.Item>
      )}
      {/* Attached guns section */}
      {weapons.guns.map(gun => (
        <Stack.Item key={gun.id}>
          <Section title={gun.name} ml='0' mr='0'>
            <Table>
              <TextRow
                caption='Слот'
                value_text={gun.primary ? 'Основное' : 'Вторичное'}
              />
              <ToggleButtonRow
                caption='Предохранитель'
                enable={gun.safety}
                enable_text='Включено'
                disable_text='Отключено'
                clicked={() => act('toggle_weapon_safety', { id: gun.id })}
              />
              <TextRow
                caption='Тип'
                value_text={get_gun_type_name(gun.type)}
              />
              <ColorTextRow
                caption='Боезапас'
                value_text={gun.ammo + '/' + gun.capacity}
                warn={gun.ammo === 0}
              />
              {gun.type === 1 ? (
                <ButtonRow
                  caption='Зарядка'
                  text='Перезарядить'
                  clicked={() => act('reload_weapon', { id: gun.id })}
                />
              ) : ('')}
              {gun.type === 2 ? (
                <ToggleButtonRow
                  caption='Зарядка'
                  enable={gun.charging}
                  enable_text='Включено'
                  disable_text='Отключено'
                  clicked={() => act('reload_weapon', { id: gun.id })}
                />
              ) : ('')}
            </Table>
          </Section>
        </Stack.Item>
      ))}
    </Stack>
  );
};


// MARK: Life support panel
type LifeSupportPanelData = {
  airtank: AirtankData;
  atmos: AtmosData;
};

type AirtankData = {
  name: string;
  enable: boolean;
  volume: string;
  pressure: string;
  low_pressure: boolean;
};

type AtmosData = {
  pressure: string;
  low_pressure: boolean;
  temperature: string;
  low_temperature: boolean;
};

const LifeSupportPanel = (props: unknown) => {
  const { act, data } = useBackend<SpacepodControlPanelData>();
  const { life_support } = data;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Table>
          <ColorTextRow
            caption='Баллон'
            value_text={life_support.airtank === null ? 'Отсутствует' : life_support.airtank.name }
            warn={life_support.airtank === null}
          />
          {life_support.airtank === null ? ('') : (
            <>
              <TextRow
                caption='Объем'
                value_text={life_support.airtank.volume}
              />
              <ColorTextRow
                caption='Давление в баллоне'
                value_text={life_support.airtank.pressure + ' Pa'}
                warn={life_support.airtank.low_pressure}
              />
              <ToggleButtonRow
                caption='Подача кислорода с баллона'
                enable={life_support.airtank.enable}
                enable_text='Включено'
                disable_text='Отключено'
                clicked={() => act('switch_airtank')}
              />
            </>
          )}
          <ColorTextRow
            caption='Давление в кабине'
            value_text={life_support.atmos.pressure + " Pa"}
            warn={life_support.atmos.low_pressure}
          />
          <ColorTextRow
            caption='Температура в кабине'
            value_text={life_support.atmos.temperature + ' K'}
            warn={life_support.atmos.low_temperature}
          />
        </Table>
      </Stack.Item>
    </Stack>
  );
};


// MARK: Elements
type ToggleButtonRowData = {
  caption: string;
  enable: boolean;
  enable_text: string;
  disable_text: string;
  clicked: any;
};

const ToggleButtonRow = (props: ToggleButtonRowData) => {
  const { caption, enable, enable_text, disable_text, clicked } = props;
  return (
    <Table.Row>
      <Table.Cell bold width="50%">{caption}:</Table.Cell>
      <Table.Cell>
        <Box pb={1}>
          <Button
              selected={enable}
              icon={enable ? 'toggle-on' : 'toggle-off'}
              onClick={() => clicked()}
          >
              { enable ? enable_text : disable_text }
          </Button>
        </Box>
      </Table.Cell>
    </Table.Row>
  )
}

type ButtonRowData = {
  caption: string;
  text: string;
  clicked: any;
};

const ButtonRow = (props: ButtonRowData) => {
  const { caption, text, clicked } = props;
  return (
    <Table.Row>
      <Table.Cell bold width="50%">{caption}:</Table.Cell>
      <Table.Cell>
        <Box pb={1}>
          <Button
              onClick={() => clicked()}
          >
              {text}
          </Button>
        </Box>
      </Table.Cell>
    </Table.Row>
  )
}


type TextRowData = {
  caption: string;
  value_text: string;
};

const TextRow = (props: TextRowData) => {
  const { caption, value_text } = props;
  return (
    <Table.Row>
        <Table.Cell bold width='50%'>{caption}:</Table.Cell>
        <Table.Cell><b>{value_text}</b></Table.Cell>
    </Table.Row>
  )
}


type TextStatusRowData = {
  caption: string;
  enable: boolean;
  enable_text: string;
  disable_text: string;
};

const TextStatusRow = (props: TextStatusRowData) => {
  const { caption, enable, enable_text, disable_text } = props;
  return (
    <Table.Row>
      <Table.Cell bold width='50%'>{caption}:</Table.Cell>
      <Table.Cell>
        <Box inline mr={1} color={enable ? 'good' : 'bad'}>
            { enable ? enable_text : disable_text }
        </Box>
      </Table.Cell>
    </Table.Row>
  )
}


type ColorTextRowData = {
  caption: string;
  value_text: string;
  warn: boolean;
};

const ColorTextRow = (props: ColorTextRowData) => {
  const { caption, value_text, warn } = props;
  return (
    <Table.Row>
      <Table.Cell bold width="50%">{caption}:</Table.Cell>
      <Box inline mr={1} color={warn ? 'bad' : 'good'}>
          {value_text}
      </Box>
    </Table.Row>
  )
}


type ErrorRowData = {
  error_text: string;
};

const ErrorRow = (props: ErrorRowData) => {
  const { error_text } = props;
  if(error_text !== null) {
    return (
      <Table.Row>
        <Table.Cell bold>Ошибка:</Table.Cell>
        <Box inline mr={1} color='bad'>
          {error_text}
        </Box>
    </Table.Row>)
  }
  return ('')
}
