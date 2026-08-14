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
    <Window width={450} height={600} title="Панель управления космическим челноком">
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
        <Section title="Аккумуляторная батарея" ml='0' mr='0'>
          <Table>
            <Table.Row>
                <Table.Cell bold width='50%'>Соединение к электросети:</Table.Cell>
                <Table.Cell>
                  <Box pb={1}>
                    <Button
                        selected={electricity.link}
                        icon={electricity.link ? 'toggle-on' : 'toggle-off'}
                        onClick={() => act('switch_powernet_link', { id: electricity.battery_id })}
                    >
                        {electricity.link ? 'Подключено' : 'Отключено'}
                    </Button>
                  </Box>
              </Table.Cell>
            </Table.Row>
            <Table.Row>
                <Table.Cell bold>Заряд батареи:</Table.Cell>
                <Table.Cell><b>{electricity.power} Вт</b></Table.Cell>
            </Table.Row>
            <Table.Row>
                <Table.Cell bold>Емкость аккумулятора:</Table.Cell>
                <Table.Cell><b>{electricity.capacity} Вт·ч</b></Table.Cell>
            </Table.Row>
            <Table.Row>
                <Table.Cell bold>Заполнение:</Table.Cell>
                <Table.Cell><b>{electricity.percent}%</b></Table.Cell>
            </Table.Row>
          </Table>
        </Section>
      </Stack.Item>
      {/* Electricity consumers section */}
      <Stack.Item grow>
        <Section fill scrollable title="Потребители">
            <Table>
                {electricity.consumers.map(consumer => (
                    <Table.Row key={consumer.id} pb={1}>
                        <Table.Cell bold width='50%'>{consumer.name}:</Table.Cell>
                        <Table.Cell>
                          <Box pb={1}>
                            <Button
                                selected={consumer.link}
                                icon={consumer.link ? 'toggle-on' : 'toggle-off'}
                                onClick={() => act('switch_powernet_link', { id: consumer.id })}
                            >
                                {consumer.link ? 'Подключено' : 'Отключено'}
                            </Button>
                          </Box>
                        </Table.Cell>
                    </Table.Row>
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
              <Table.Row>
                <Table.Cell bold width='50%'>Состояние:</Table.Cell>
                <Table.Cell>
                  <Box pb={1}>
                    <Button
                        selected={engine.enable}
                        icon={engine.enable ? 'toggle-on' : 'toggle-off'}
                        onClick={() => act('switch_enable', { id: engine.id })}
                    >
                        {engine.enable ? 'Запущено' : 'Отключено'}
                    </Button>
                  </Box>
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Обороты:</Table.Cell>
                  <Box inline mr={1} color={engine.rpm_warn ? 'bad' : 'good'}>
                      {engine.rpm} RPM
                  </Box>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Мощность:</Table.Cell>
                  <Box inline mr={1} color={engine.rpm_warn ? 'bad' : 'good'}>
                      {engine.rpm_percent}%
                  </Box>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Давление топлива:</Table.Cell>
                  <Box inline mr={1} color={engine.fuel_pressure_warn ? 'bad' : 'good'}>
                      {engine.fuel_pressure}%
                  </Box>
              </Table.Row>
              {engine.rpm_provide_engines !== null ? (
                <Table.Row>
                  <Table.Cell bold>Передача крутящего момента:</Table.Cell>
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
              <Table.Row>
                <Table.Cell bold width='50%'>Генератор:</Table.Cell>
                <Table.Cell>
                  <Box pb={1}>
                    <Button
                        selected={engine.generator_enable}
                        icon={engine.generator_enable ? 'toggle-on' : 'toggle-off'}
                        onClick={() => act('switch_generator_enable', { id: engine.id })}
                    >
                        {engine.generator_enable ? 'Запущено' : 'Отключено'}
                    </Button>
                  </Box>
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Генерация электричества:</Table.Cell>
                  <Box inline mr={1}>
                      {engine.generated_power} Ватт
                  </Box>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Температура:</Table.Cell>
                  <Box inline mr={1} color={engine.temperature_warn ? 'bad' : 'good'}>
                      {engine.temperature} C
                  </Box>
              </Table.Row>
              {engine.error_text !== null ? (
                <Table.Row>
                  <Table.Cell bold>Ошибка:</Table.Cell>
                  <Box inline mr={1} color='bad'>
                      {engine.error_text}
                  </Box>
                </Table.Row>
              ) : ''}
            </Table>
          </Section>
        </Stack.Item>
      ))}
      {engines.gyroscope !== null ? (
        <Stack.Item>
          <Section title={engines.gyroscope.name} ml='0' mr='0'>
            <Table>
              <Table.Row>
                <Table.Cell bold width='50%'>Соединение к электросети:</Table.Cell>
                <Table.Cell>
                  <Box inline mr={1} color={engines.gyroscope.power_link ? 'good' : 'bad'}>
                      {engines.gyroscope.power_link ? 'Подключено' : 'Отключено'}
                  </Box>
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell bold>Состояние:</Table.Cell>
                <Table.Cell>
                  <Box pb={1}>
                    <Button
                        selected={engines.gyroscope.enable}
                        icon={engines.gyroscope.enable ? 'toggle-on' : 'toggle-off'}
                        onClick={() => act('switch_enable', { id: engines.gyroscope.id })}
                    >
                        {engines.gyroscope.enable ? 'Запущено' : 'Отключено'}
                    </Button>
                  </Box>
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Обороты:</Table.Cell>
                  <Box inline mr={1} color={engines.gyroscope.rpm_warn ? 'bad' : 'good'}>
                      {engines.gyroscope.rpm} RPM
                  </Box>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Мощность:</Table.Cell>
                  <Box inline mr={1} color={engines.gyroscope.rpm_warn ? 'bad' : 'good'}>
                      {engines.gyroscope.rpm_percent}%
                  </Box>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Температура:</Table.Cell>
                  <Box inline mr={1} color={engines.gyroscope.temperature_warn ? 'bad' : 'good'}>
                      {engines.gyroscope.temperature} C
                  </Box>
              </Table.Row>
              {engines.gyroscope.error_text !== null ? (
                <Table.Row>
                  <Table.Cell bold>Ошибка:</Table.Cell>
                  <Box inline mr={1} color='bad'>
                      {engines.gyroscope.error_text}
                  </Box>
                </Table.Row>
              ) : ''}
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
              <Table.Row>
                  <Table.Cell bold width='50%'>Емкость топлива:</Table.Cell>
                  <Table.Cell><b>{fuel_tank.fuel_capacity} л.</b></Table.Cell>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Уровень топлива:</Table.Cell>
                  <Table.Cell><b>{fuel_tank.fuel_amount} л.</b></Table.Cell>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Уровень в прцоентах:</Table.Cell>
                  <Table.Cell><b>{fuel_tank.level_percent}%</b></Table.Cell>
              </Table.Row>
            </Table>
          </Section>
        </Stack.Item>
      ))}
      {/* Fuel pumps section */}
      {fuel.fuel_pumps.map(fuel_pump => (
        <Stack.Item key={fuel_pump.id}>
          <Section title={fuel_pump.name} ml='0' mr='0'>
            <Table>
              <Table.Row>
                <Table.Cell bold width='50%'>Соединение к электросети:</Table.Cell>
                <Table.Cell>
                  <Box inline mr={1} color={fuel_pump.power_link ? 'good' : 'bad'}>
                      {fuel_pump.power_link ? 'Подключено' : 'Отключено'}
                  </Box>
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell bold width='50%'>Состояние:</Table.Cell>
                <Table.Cell>
                  <Box pb={1}>
                    <Button
                        selected={fuel_pump.enable}
                        icon={fuel_pump.enable ? 'toggle-on' : 'toggle-off'}
                        onClick={() => act('switch_enable', { id: fuel_pump.id })}
                    >
                        {fuel_pump.enable ? 'Запущено' : 'Отключено'}
                    </Button>
                  </Box>
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Скорость перекачки:</Table.Cell>
                  <Box inline mr={1}>{fuel_pump.pump_speed} литр/сек</Box>
              </Table.Row>
              <Table.Row>
                  <Table.Cell bold>Температура:</Table.Cell>
                  <Box inline mr={1} color={fuel_pump.temperature_warn ? 'bad' : 'good'}>
                      {fuel_pump.temperature} C
                  </Box>
              </Table.Row>
              {fuel_pump.error_text !== null ? (
                <Table.Row>
                  <Table.Cell bold>Ошибка:</Table.Cell>
                  <Box inline mr={1} color='bad'>
                      {fuel_pump.error_text}
                  </Box>
                </Table.Row>
              ) : ''}
            </Table>
          </Section>
        </Stack.Item>
      ))}
    </Stack>
  );
};
