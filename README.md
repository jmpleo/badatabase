# Обновленное взаимодействие с БД

Зависимости:

- pqxx 7.2.1
- nlohman 3.10.5-2

Что изменено:

- Функции взаимодействия с БД теперь более масштабируемые
- Логика взаимодействия с выборкой данных перенесена на сторону сервера

## Создание новых БД

Новая база данных содержит необходимые серверные процедуры для эффективной и масштабируемой работы с базой. В связи с этим, рекомендуется создавать новые БД используя обновленную схему:

```bash
cd sql
./mainsql-gen.sh
./init-db.sh <имя базы данных>
```

Несмотря на это, обновленное взаимодействие с БД, основанное на серверных процедурах, имеет обратную совместимость со старыми схемами БД. (При каждом соединении осуществляется обновление схемы в соответствии со скриптом `sql/main.sql`)

## Подключение к соединению

Интерфейс нового `BADataBase` практически полностью поддерживает старый интерфейс:

```c++
BADataBase() = delete;
BADataBase(BADataBase const&) = delete;
BADataBase operator = (BADataBase const&) = delete;

BADataBase(string);

string getConnectionName() const;
string setDevice(BADeviceInfo& d);

int addZone  (Zone&, InsertMod = InsertMod::Quiet);
int addSensor(Sensor&, InsertMod = InsertMod::Quiet);
int addLine  (SensorLine&, InsertMod = InsertMod::Quiet);
int addSweep (SweepLorenzResult&, InsertMod = InsertMod::Quiet);

bool delLine  (int lineId);
bool delZone  (int zoneId);
bool delSweep (int sweepId);
bool delSensor(int sensorId);

bool tryConnect (string connectionName = "");
bool copyFrom   (BADataBase &src, Table, CopyMod);
bool isConnected();

vector <SensorLine> getSensorLines(int sensorId);
vector <Zone>       getSensorZones(int sensorId);
vector <SensorDB>   getSensorsDB();
BADeviceInfo        getBADeviceInfo();
string              getBADeviceInfoId();
SweepLorenzResult   getSweepLorenzResult(int sensorId, string time);

vector <pair <int, string>>
getAllSweepByTime(string startTime = "" , const bool includes = true);

vector <pair <int, string>>
sensorListTime(int sensorId, string startTime="");
```

## Конфигурация настроек соединений

Каждый раз, когда классу `BADataBase` необходимо подключиться к новому соединению, а также кешированию ID устройства, происходит поиск строки подключения в конфигурационном файле. Этим файлом полностью управляет синглон `ConnConfManager`. В начальный момент инициализации, путь до файла конфигурации определяется как путь по умолчанию указанный `CMakeLists.txt`. Интерфейс менеджера позволяет добавлять и удалять соединения в базе:

```c++
void setConnectionOptions(string connName, string paramsLine);
void setDevice           (string connName, string id);
void removeConnection    (string connName);
bool connectionExists    (string connName);

string getConnectionOptions(string connName);
string getDevice           (string connName);
string rollupOptions       (mapped_param);

map <string, string> getSplitedConnectionOptions(string connName);
map <string, string> splitOptions               (string optionsLine);

vector<string> getConnectionsList();

void setConfigPath(string newConfigPath = _DEFAULT_DB_CONFIG_PATH);
```

Чтобы получить доступ к менеджеру файла конфигурации текущего соединения необходимо обратиться к статическому полю `BABase::config` : 

```cpp
string deviceId = BADataBase::config.getDeice("myConnection");
```

