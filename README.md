# Обновленное взаимодействие с БД

Зависимости:

- pqxx 7.2.1
- nlohman 3.10.5-2

Что изменено:

- Функции взаимодействия с БД теперь более масштабируемые

- Логика взаимодействия с выборкой данных перенесена на сторону сервера
- Менеджер конфигурации соединений и подключения соединений оформлены в виде синглтонов

## Создание новых БД

Новая база данных содержит необходимые серверные процедуры для эффективной и масштабируемой работы с базой. В связи с этим, рекомендуется создавать новые БД используя обновленную схему:

```bash
cd sql
./mainsql-gen.sh
./init-db.sh <имя базы данных>
```

Несмотря на это, обновленное взаимодействие с БД, основанное на серверных процедурах, имеет обратную совместимость со старыми схемами БД. (При каждом соединении осуществляется обновление схемы в соответствии со скриптом `sql/main.sql`) 

## Подключение к соединению

Класс `ConnManager` - синглтон для поддержки текущего соединения и подключению новых. Для создания нового соединения необходимо вызвать статический метод `touch()`:

```   c++
if (ConnManager::touch(<название соединения>[, <количество попыток>])) {
    /// действия с соединением
}
```

Чтобы использовать это соединение, необходимо использовать метод `conn()`, возвращающий ссылку на `BADataBase`.

```c++
if (ConnManager::touch(<название соединения>[, <количество попыток>])) {
    Zone z;
    ConnManager::conn().addZone(z);
}
```

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

Помимо поддержки текущего соединения, `ConnManager` может подключать и другие `BADataBase`:

```c++
BADataBase conn(<название соединения>);

if (ConnManager::touch(сonn [,<количество попыток>])) {
    Zone z;
    conn.addZone(z);
    
    // ConnManager::conn() - не изменяется после вызова touch(BADataBase&)
}
```

## Конфигурация настроек соединений

Каждый раз, когда классу `BADataBase` необходимо подключиться к новому соединению, а также кешированию ID устройства, происходит поиск строки подключения в конфигурационном файле. Этим файлом полностью управляет синглон `ConnConfManager`. В начальный момент инициализации, путь до файла конфигурации определяется как путь по умолчанию указанный в скрипте для сборки проекта `badatabase`: `./confugre`. Интерфейс менеджера позволяет добавлять и удалять соединения в базе:

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

