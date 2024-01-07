## Quick start

Сгенерируйте файл `main.sql`:

```bash
./initgen.sh
```

Настройте конфигурации БД в файле`.env`:

```bash
POSTGRES_DB=badatabase
POSTGRES_USER=badatabase
POSTGRES_PASSWORD=badatabase
POSTGRES_HOST_AUTH_METHOD="scram-sha-256\nhost replication all 0.0.0.0/0 md5\nhostssl all all all cert\n "
POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256"

# for fill.py script
DATABASE_HOST=localhost
DATABASE_PORT=5454
DATABASE_NAME=badatabase
DATABASE_USER=badatabase
DATABASE_PASSWORD=badatabase
```

А также виртуальное окружение`.env.replica` - для сервера-реплики:

```bash
PGUSER=replicator
PGPASSWORD=replicator
```

Запустите `badatabase_primary` и реплику `badatabase_replica` используя `docker-compose`:

```bash
docker-compose up
```

## Отчет: Построение защищенных СУБД

### Описание предметной области

#### Анализ характеристик оптоволоконного кабеля: бриллюэновский анализатор спектра частот.

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
- `*_labeler` - Разметчик данных линий или зон частотных характеристик. Имеет доступ на чтение и запись таблицы `sensorslines` или `zones`. 
- `viewer` - Обычный пользователь, имеющий доступ на чтение данных в таблицах.

```postgresql

CREATE ROLE admin WITH LOGIN PASSWORD 'admin';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

CREATE ROLE zones_labeler WITH LOGIN PASSWORD 'zones_labeler';
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO zones_labeler;
GRANT ALL PRIVILEGES ON zones TO zones_labeler;
GRANT ALL PRIVILEGES ON labelers TO zones_labeler;
GRANT SELECT ON select_labelersecret TO zones_labeler;
GRANT ALL PRIVILEGES ON labelerskeys TO zones_labeler;

CREATE ROLE sensorslines_labeler WITH LOGIN PASSWORD 'sensorslines_labeler';
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO sensorslines_labeler;
GRANT ALL PRIVILEGES ON sensorslines TO sensorslines_labeler;
GRANT ALL PRIVILEGES ON labelers TO sensorslines_labeler;
GRANT SELECT ON select_labelersecret TO sensorslines_labeler;
GRANT ALL PRIVILEGES ON labelerskeys TO sensorslines_labeler;

CREATE ROLE auditor WITH LOGIN PASSWORD 'auditor';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor;


```

### Тщательный контроль доступа (RLS)

Создадим пользователей, для которых будем настраивать разграничение доступа. Предоставим доступ к таблицам разметки `sensorslines` и `zones` в соответствии определенному сенсору.

```postgresql
ALTER TABLE sensorslines ENABLE ROW LEVEL SECURITY;
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE labelerskeys ENABLE ROW LEVEL SECURITY;

CREATE POLICY sensorslines_labeler_sensor_1_view ON sensorslines FOR
    SELECT TO sensorslines_labeler_sensor_1 USING (sensorid = 1);

CREATE POLICY zones_labeler_sensor_1_view ON zones FOR
    SELECT TO zones_labeler_sensor_1 USING (sensorid = 1);

CREATE POLICY admin_view_sensorslines ON sensorslines FOR
    ALL TO admin USING (TRUE);

CREATE POLICY admin_view_zones ON zones FOR
    ALL TO admin USING (TRUE);

CREATE POLICY auditor_sensor_1_view_sensorlines ON sensorslines FOR
    SELECT TO auditor_sensor_1 USING (sensorid = 1);

CREATE POLICY auditor_sensor_1_view_zones ON zones FOR
    SELECT TO auditor_sensor_1 USING (sensorid = 1);

CREATE POLICY sensorslines_labeler_view_only_self_key ON labelerskeys FOR
    SELECT TO sensorslines_labeler USING (labelername = CURRENT_USER);

CREATE POLICY zones_labeler_view_only_self_key ON labelerskeys FOR
    SELECT TO zones_labeler USING (labelername = CURRENT_USER);

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

Для аудита уровня БД необходимо выставить параметр `log_statement=all` в конфигурационном файле `postgresql.conf`

### Контроль целостности

Свзязность таблиц и ограничения, задаваемые в скриптах `entity/*.sql`, обеспечивают декларативный контроль целостности.

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

### Шифрование

Реализовано на примере тестовой таблицы`labelers` (`sql/entity/labelers.sql`). Прозрачное шифрование столбца `labelersecret` таблицы `labelers` обеспечивается триггером `insert_labelers_trigger`:

```postgresql
CREATE OR REPLACE FUNCTION insert_labeler_handle()
RETURNS TRIGGER AS $$
BEGIN
    IF
        CURRENT_USER NOT IN (SELECT labelername FROM labelerskeys)
    THEN
        RAISE EXCEPTION 'User have not a key';
    END IF;

    IF
        NEW.labelername != CURRENT_USER
        AND
        NEW.labelername != 'admin'
    THEN
        RAISE EXCEPTION 'Permission denied to update data';
    END IF;

    NEW.labelersecret:= pgp_sym_encrypt(
        NEW.labelersecret,
        (SELECT labelerkey FROM labelerskeys WHERE labelername = CURRENT_USER)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER insert_labeler_trigger
BEFORE
    INSERT OR UPDATE ON labelers
FOR
    EACH ROW
EXECUTE
    FUNCTION insert_labeler_handle();
```

Расшифрование обеспечивается представлением:

```postgresql
CREATE OR REPLACE VIEW select_labelersecret AS
    SELECT
        select_labelersecret(labelersecret, labelername) AS labelersecret
    FROM
        labelers
    WHERE labelername = CURRENT_USER;
```

Для этого используется функция расшифрования:

```postgresql 
CREATE OR REPLACE FUNCTION select_labelersecret(p_secret TEXT, p_labelername TEXT)
RETURNS TEXT AS $$
DECLARE
    decrypt_secret TEXT;
BEGIN
    IF
        CURRENT_USER NOT IN (SELECT labelername FROM labelerskeys)
    THEN
        RAISE EXCEPTION 'User does not have a key';
    END IF;

    IF
        p_labelername != 'admin'
        AND
        p_labelername != CURRENT_USER
    THEN
        RAISE EXCEPTION 'Permission denied to update data';
    END IF;

    decrypt_secret := pgp_sym_decrypt(
        p_secret::BYTEA,
        (SELECT labelerkey FROM labelerskeys WHERE labelername = CURRENT_USER)
    );
    RETURN decrypt_secret;
END;
$$ LANGUAGE plpgsql;
```

Ключи шифрования хранятся в таблице `labelers_keys`, доступ к которой разграничивается политиками RLS:

```postgresql
CREATE POLICY sensorslines_labeler_view_only_self_key ON labelerskeys FOR
    SELECT TO sensorslines_labeler USING (labelername = CURRENT_USER);

CREATE POLICY zones_labeler_view_only_self_key ON labelerskeys FOR
    SELECT TO zones_labeler USING (labelername = CURRENT_USER);
```

Таким образом, пользователь может добавлять, обновлять свой ключ в `labelerskeys`:

```
badatabase@zones_labeler=> insert into labelerskeys(labelerkey, labelername) values ('zones_labeler', 'zones_labeler');

INSERT 0 1
```

```
badatabase@badatabase=# insert into labelerskeys(labelerkey, labelername) values ('badatabase', 'badatabase');

INSERT 0 1
```

```
badatabase@zones_labeler=> select * from labelerskeys;

 keyid | labelerkey    |  labelername  
-------+---------------+---------------
     2 | zones_labeler | zones_labeler
(1 row)
```

Для шифрования достаточно просто добавить запись в таблицу `labelers`:

```
badatabase@zones_labeler=> insert into labelers(labelersecret) values ('zones_labeler');

INSERT 0 1
```

```
badatabase@badatabase=> insert into labelers(labelersecret) values ('badatabase');

INSERT 0 1
```

Данные в таблице `labelers` хранятся в зашифрованном виде:

```
badatabase@zones_labeler=> select * from labelers;

labelerid |  labelername  |                                                                           labelersecret                                                                            
-----------+---------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------
         1 | badatabase    | \xc30d04070302161d10539f60b8657dd23b01f740075c186329a7883e41db7f579782d9882fde27f3df6b2b95a3942426c244735193868494df4bd136c940e722a9edd1da5fb40876af5a69ab
         2 | zones_labeler | \xc30d04070302873941fd7f1fb82573d23f01158ac7730f738053e8613dd289cab2253c151c44f92f8c1213ad9846ac9ff2e1dfc21f929df5f5c83180a11186d9e270012644319c233a2b71b3e1133422
(2 rows)

```

Для расшифрования необходимо сделать выборку из представления:

```
badatabase@zones_labeler=> select * from select_labelersecret;

 labelersecret  
----------------
 zones_labelers
(1 row)
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

Реплика доступна только для чтения на порту `5353`, а сервер-мастер на `5454`.

### Внешняя аутентификация

