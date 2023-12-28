## Quick start

Сгенерируйте файл `main.sql`:

```bash
./mainsql-gen.sh
```

Настройте конфигурации БД в файле`.env`:

```bash
POSTGRES_USER=badatabase
POSTGRES_PASSWORD=<your sec password>
POSTGRES_DB=badatabase
```

Запустите сервер БД используя `docker-compose`:

```bash
docker-compose up
```

## Отчет: Построение защищенных СУБД

@jmpleo @1193221

---

### Описание предметной области

Анализ характеристик оптоволоконного кабеля: бриллюэновский анализатор спектра частот.

### Сущности

- `badeviceinfo` - Конфигурация устройства бриллюэновского анализатора.
- `sensors` - Характеристики сенсора устройства.
- `sensorslines` - Параметры отрезка снятых сенсором характеристик.
- `zones` - Параметры определенной зона на участке линии.
- `sweepdatalorenz` - Непосредственно характеристики (частоты) снятые сенсором. 

### ER-диаграмма

![diagl](./img/diagl.png)

### Ролевая модель безопасности

Роли СУБД: 

- `admin` - Пользователь, имеющий доступ ко всем таблицам на чтение и запись
- `labler` - Разметчик данных линий и зон частотных характеристик. Имеет доступ на чтение и запись таблиц `sensorslines`, `zones`. 
- `viewer` - Обычный пользователь, имеющий доступ на чтение данных в таблицах.

```postgresql
-- Создание роли "admin"
CREATE ROLE admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

-- Создание роли "labler"
CREATE ROLE labler;
GRANT SELECT, INSERT ON sensorslines TO labler;
GRANT SELECT, INSERT ON zones TO labler;

-- Создание роли "viewer"
CREATE ROLE viewer;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer;
```

### Тщательный контроль доступа (RLS)

Создадим пользователей, для которых будем настраивать разграничение доступа. Предоставим доступ к таблицам разметки `sensorslines` и `zones` в соответствии определенному сенсору.

```postgresql
CREATE USER zones_labler_sensor_1 WITH PASSWORD 'zones_labler_sensor_1';
GRANT zones_labler to zones_labler_sensor_1;

CREATE USER sensorslines_labler_sensor_1 WITH PASSWORD 'sensorslines_labler_sensor_1';
GRANT sensorslines_labler to sensorslines_labler_sensor_1;

CREATE USER auditor_sensor_1 WITH PASSWORD 'auditor_sensor_1';
GRANT auditor to auditor_sensor_1;
```

Теперь настроим политики для пользователей, разграничив выбор для определенных столбцов в зависимости от `sensorid`.

```postgresql
ALTER TABLE sensorslines ENABLE ROW LEVEL SECURITY;
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY view_sensor_1 ON sensorslines FOR
    SELECT TO sensorslines_labler_sensor_1 USING (sensorid = 1);

CREATE POLICY view_sensor_1 ON zones FOR
    SELECT TO zones_labler_sensor_1 USING (sensorid = 1);

CREATE POLICY view_all ON sensorslines FOR
    ALL TO admin USING (TRUE);

CREATE POLICY view_all ON zones FOR
    ALL TO admin USING (TRUE);

CREATE POLICY view_sensor_1 ON sensorslines FOR
    SELECT TO auditor_sensor_1 USING (sensorid = 1);

CREATE POLICY view_sensor_1 ON zones FOR
    SELECT TO auditor_sensor_1 USING (sensorid = 1);
```

### Политика аудита и тщательного аудита FGA

Создадим основные таблицы аудита таблиц разметки, а также триггеры для обработки соответствующих действий.

```postgresql
CREATE TYPE dml_type AS ENUM ('INSERT', 'UPDATE', 'DELETE');

CREATE TABLE IF NOT EXISTS sensorslines_audit_log (
    line_id INTEGER NOT NULL,
    old_row_data JSONB,
    new_row_data JSONB,
    dml_type dml_type NOT NULL,
    dml_timestamp TIMESTAMP NOT NULL,
    dml_created_by VARCHAR(255) NOT NULL,
    PRIMARY KEY (line_id, dml_type, dml_timestamp)
);


CREATE TABLE IF NOT EXISTS zones_audit_log (
    zone_id INTEGER NOT NULL,
    old_row_data JSONB,
    new_row_data JSONB,
    dml_type DML_TYPE NOT NULL,
    dml_timestamp TIMESTAMP NOT NULL,
    dml_created_by VARCHAR(255) NOT NULL,
    PRIMARY KEY (line_id, dml_type, dml_timestamp)
);
```

```postgresql
CREATE OR REPLACE TRIGGER sensorslines_audit_log_trigger
    AFTER
        INSERT OR UPDATE OR DELETE
    ON
        sensorslines
    FOR
        EACH ROW
    EXECUTE FUNCTION
        sensorslines_audit_log_trigger_handle();


CREATE OR REPLACE TRIGGER zones_audit_log_trigger
    AFTER
        INSERT OR UPDATE OR DELETE
    ON
        zones
    FOR
        EACH ROW
    EXECUTE FUNCTION
        zones_audit_log_trigger_handle();
```

Для аудита уровня БД необходимо выставить параметр `log_statement=all` в конфигурационном файле `postgresql.conf`.

Тогда можно бедт наблюдать логирование всех запросов к БД:

```bash
sudo cat /var/log/postgresql/postgresql-<version>-main.log
```

### Контроль целостности

Свзяность таблиц и ограничения, задаваемые в скриптах `entity/*.sql`, обеспечивают декларативный контроль целостности.

Примером процедурного контроля целостности служит триггер `trigger/point.sql` на осуществление контроля за связкой полей таблицы `sensors`: `sensorstartpoint`, `sensorendpoint`, `sensorpointlength`.

`func/handler-point.sql`

```postgresql
CREATE OR REPLACE FUNCTION sensor_points_handle()
RETURNS TRIGGER AS $$
BEGIN
    IF
        NEW.sensorstartpoint IS NOT NULL
        AND NEW.sensorendpoint IS NOT NULL
        AND NEW.sensorpointlength IS NULL
    THEN
        NEW.sensorpointlength := NEW.sensorendpoint - NEW.sensorstartpoint;
    ELSIF
        NEW.sensorstartpoint IS NOT NULL
        AND NEW.sensorpointlength IS NOT NULL
        AND NEW.sensorendpoint IS NULL
    THEN
        NEW.sensorendpoint := NEW.sensorstartpoint + NEW.sensorpointlength;
    ELSIF
        NEW.sensorendpoint IS NOT NULL
        AND NEW.sensorpointlength IS NOT NULL
        AND NEW.sensorstartpoint IS NULL
    THEN
        NEW.sensorstartpoint := NEW.sensorendpoint - NEW.sensorpointlength;
    ELSIF
        NEW.sensorendpoint IS NOT NULL
        AND NEW.sensorpointlength IS NOT NULL
        AND NEW.sensorstartpoint IS NOT NULL
        AND NEW.sensorpointlength <> NEW.sensorendpoint - NEW.sensorstartpoint
    THEN
        RAISE EXCEPTION 'The sensor length does not match the specified start and end points';
    ELSE
        RAISE EXCEPTION 'You must specify at least two out of three parameters: start, end, length';
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;
```

### Ширфование

Реализовано на примере тестовой таблицы`labelers_notes` (`sql/entity/labelers.sql`). Прозрачное шифрование столбца `note` таблицы `labelers_notes` обеспечивается триггером `notes_encryption_trigger`. Ключи шифрования храняться в таблице `labelers_keys`, доступ к которой разграничивается политиками RLS:

```postgresql
CREATE POLICY sensorslines_labeler_view_only_self_key ON labelers_keys FOR
    SELECT TO sensorslines_labeler USING (labelername = CURRENT_USER);

CREATE POLICY zones_labeler_view_only_self_key ON labelers_keys FOR
    SELECT TO zones_labeler USING (labelername = CURRENT_USER);
```

### Резервное копирование. Репликация

В качестве политики резервирования реализован метод репликации в режиме **master-slave**.

Для этого была создана роль репликатора на **slave** сервере, и выделен слот репликации:

```postgresql
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator';
SELECT pg_create_physical_replication_slot('replication_slot');
```

Взаимодействие **master-slave** реализовано через **docker-compose**:

```yaml
version: '3.8'
x-postgres-common:
  &postgres-badatabase
  image: postgres:15.5-alpine
  user: postgres
  restart: always
  healthcheck:
    test: 'pg_isready -U badatabase --dbname=badatabase'
    interval: 10s
    timeout: 5s
    retries: 5

services:
  badatabase_primary:
    <<: *postgres-badatabase
    ports:
      - 5454:5432
    env_file:
      - .env
    command: |
      postgres
      -c wal_level=replica
      -c hot_standby=on
      -c max_wal_senders=10
      -c max_replication_slots=10
      -c hot_standby_feedback=on
    volumes:
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
      - pgdata:/var/lib/postgresql/data

  badatabase_replica:
    <<: *postgres-badatabase
    ports:
      - 5353:5432
    env_file:
      - .env.replica
    volumes:
      - pgdata_replica:/var/lib/postgresql/data
    command: |
      bash -c "
      until pg_basebackup --pgdata=/var/lib/postgresql/data -R --slot=replication_slot --host=badatabase_primary --port=5432
      do
      echo 'Waiting for primary to connect...'
      sleep 1s
      done
      echo 'Backup done, starting replica...'
      chmod 0700 /var/lib/postgresql/data
      postgres
      "
    depends_on:
      - badatabase_primary

volumes:
  pgdata:
  pgdata_replica:
```

### Внешняя аутентификация

