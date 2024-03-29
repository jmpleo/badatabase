## Quick start

Настройте master-сервер

**primary/primary.env**

```bash
POSTGRES_DB=badatabase
POSTGRES_USER=badatabase
POSTGRES_PASSWORD=badatabase
#kerberos auth
#POSTGRES_HOST_AUTH_METHOD="            gss include_realm=0 krb_realm=BADATABASE.LOCAL
POSTGRES_HOST_AUTH_METHOD="            scram-sha-256
host       replication  all 0.0.0.0/0  md5
hostssl    all          all all        cert
hostgssenc all          all all        gss include_realm=0 krb_realm=BADATABASE.LOCAL
"
```

Настройте окуружение slave-сервера

**replica/replica.env**

```bash 
PGUSER=replicator
PGPASSWORD=replicator
```

Настройте окуружение backup-сервиcа

**backup/backup.env**

```bash
PGUSER=badatabase
PGPASSWORD=badatabase
```

> PGUSER и PGPASSWORD используются для аутентификации на сервере при использовании утилиты `pg_basebackup` 

Запустите

```bash
docker-compose up -d primary backup replica 
```

### Kerberos auth

Если нужно использовать аутентификацию через kerberos, то поменяйте метод аутентификации:

**primary/primary.env**

```bash
POSTGRES_DB=badatabase
POSTGRES_USER=badatabase
POSTGRES_PASSWORD=badatabase
#POSTGRES_HOST_AUTH_METHOD="            scram-sha-256
POSTGRES_HOST_AUTH_METHOD="            gss include_realm=0 krb_realm=BADATABASE.LOCAL
host       replication  all 0.0.0.0/0  md5
hostssl    all          all all        cert
hostgssenc all          all all        gss include_realm=0 krb_realm=BADATABASE.LOCAL
"
```

Настройте kerberos окуружение

**kerberos/kerberos.env**

```bash
REALM=BADATABASE.LOCAL
SUPPORTED_ENCRYPTION_TYPES=aes256-cts-hmac-sha1-96:normal
KADMIN_PRINCIPAL=kadmin/admin
KADMIN_PASSWORD=MITiys4K5
POSTGRES_PRINCIPAL_PASSWORD=postgres
POSTGRES_PRIMARY=postgres
KDC_HOSTNAME=kdc.badatabase.local
POSTGRES_HOSTNAME=primary.badatabase.local
CLIENT_PRINCIPAL=badatabase
CLIENT_PRINCIPAL_PASSWORD=badatabase
```

и запустите

```bash
docker-compose up -d primary kdc backup replica
```

> Перед этим не забудьте удалить сконфигурированные старые сервисы (если такие создавались) командой `docker-compose down -v`

чтобы проверить аутентификацию запустите клиент сервис:

```bash
docker-compose up client
```

### Test data fill

Заполните БД тестовыми данными:

```bash
pipenv run python3 fill.py -H localhost -P 5454 -D badatabase -U badatabase -W badatabase --devices 1 --sensors 5 --sweeps 100
```

> Если выбран метод аутентификации через kerberos то сначала нужно скопировать файл `badatabase.keytab` на хост машину, скопировать `kerberos/krb5.conf` в `etc/krb5.conf` и получить билет: `kinit -k -t badatabase.keytab badatabase`

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

Сервис `badatabase_replica` настроет аналогично `badatabase_primary` и доступен по `5353` порту только для чтения:

```yaml
badatabase_replica:
    <<: *postgres
    build: ./replica
    ports:
      - 5353:5432
    env_file:
      - ./replica/replica.env
    volumes:
      - pgdata_replica:/var/lib/postgresql/data
    depends_on:	
      - badatabase_primary
```

Чтобы запустить репликацию, необходимо подготовить начальное состояние реплики. Это делается с помощью `pg_basebackup`:

```bash
#!/bin/sh

rm -rf /var/lib/postgresql/data/*

until pg_basebackup --pgdata=/var/lib/postgresql/data -R --slot=replication_slot --host=badatabase_primary --port=5432
do
    echo 'Waiting for primary to connect...'
    sleep 1s
done

echo 'Backup done, starting replica...'

chmod 0700 /var/lib/postgresql/data

postgres
```

Параметр  `-R` упрощает запуск реплики в режиме постоянного восстановления (что по сути и есть репликация), `pg_basebackup` создает специальные файлы `standby.signal` и  `postgresql.auto.conf` в `$PGDATA`. 

Параметр `--slot=replication_slot` указывает, что утилита `pg_basebackup` должна использовать тот же слот репликации, который был создан в `init.sql` сценарий основного экземпляра. 

Реплика доступна только для чтения на порту `5353`, а сервер-мастер на `5454`.

### Внешняя аутентификация

Реализуем внешнюю аутентификацию через kerberos. Для этого добавим строку соединений `hostgssenc all all all gss include_realm=0 krb_realm=BADATABASE.LOCAL`в `pg_hba.conf` из виртуального окружения 

**primary/primary.env**

```bash
POSTGRES_DB=badatabase
POSTGRES_USER=badatabase
POSTGRES_PASSWORD=badatabase
POSTGRES_HOST_AUTH_METHOD="            gss include_realm=0 krb_realm=BADATABASE.LOCAL
host       replication  all 0.0.0.0/0  md5
hostssl    all          all all        cert
hostgssenc all          all all        gss include_realm=0 krb_realm=BADATABASE.LOCAL
"
```

Добавим сервисы `KDC` и клиента, через который будем тестировать аутентификацию:

```yaml
kdc:
    container_name: kdc
    build: ./kerberos/kdc
    env_file: ./kerberos/kerberos.env
    volumes:
      - /dev/urandom:/dev/random
      - client-keytab:/client-keytab
      - postgres-keytab:/postgres-keytab
      - ./kerberos/krb5.conf:/etc/krb5.conf
    networks:
      - realm-network
    hostname: kdc.badatabase.local

  client:
    container_name: client
    build: ./kerberos/client
    env_file: ./kerberos/kerberos.env
    depends_on:
      - kdc
    volumes:
      - client-keytab:/keytab
      - ./kerberos/krb5.conf:/etc/krb5.conf
    networks:
      - realm-network
    hostname: client.badatabase.local
```

Для этих сервисов необходимо настроить виртуальное окружение `kerberos/kerberos.env`:

```bash
REALM=BADATABASE.LOCAL
SUPPORTED_ENCRYPTION_TYPES=aes256-cts-hmac-sha1-96:normal
KADMIN_PRINCIPAL=kadmin/admin
KADMIN_PASSWORD=MITiys4K5
POSTGRES_PRINCIPAL_PASSWORD=postgres
POSTGRES_PRIMARY=postgres
KDC_HOSTNAME=kdc.badatabase.local
POSTGRES_HOSTNAME=primary.badatabase.local
CLIENT_PRINCIPAL=badatabase
CLIENT_PRINCIPAL_PASSWORD=badatabase
```

При инициализации `kdc` будут созданы принципалы `postgres/primary.badatabas.local` для сервера `primary` и `badatabase` для аутентификации пользователя `badatabase`. Для них будут созданы файлы `keytab` в соответствующих монтируемых папках:

**kerberos/kdc/init-script.sh**

```bash
kadmin.local -q "delete_principal -force $POSTGRES_PRINCIPAL@$REALM"
kadmin.local -q "addprinc -pw $POSTGRES_PRINCIPAL_PASSWORD $POSTGRES_PRINCIPAL@$REALM"
kadmin.local -q "ktadd -k /postgres-keytab/postgres.keytab -norandkey $POSTGRES_PRINCIPAL@$REALM"


kadmin.local -q "delete_principal -force $CLIENT_PRINCIPAL@$REALM"
kadmin.local -q "addprinc -pw $CLIENT_PRINCIPAL_PASSWORD $CLIENT_PRINCIPAL@$REALM"
kadmin.local -q "ktadd -k /client-keytab/$CLIENT_PRINCIPAL.keytab -norandkey $CLIENT_PRINCIPAL@$REALM"
```

Добавим монтируемые папки с `keytab` в соответствующие сервисы `primary` и `client` и укажем `postgres` путь до `postgres.keytab`:

**docker-compose.yml** 

```yaml
primary:
  ...
  volumes:
    - postgres-keytab:/keytab
  ...
  command: |
    postgres
    -c krb_server_keyfile='/keytab/postgres.keytab'
  ...

kdc:
  ...
  volumes:
    - client-keytab:/client-keytab
    - postgres-keytab:/postgres-keytab
  ...
client:
  ...
  volumes:
    - client-keytab:/keytab
  ...
```

При инициализации, клиент получает билет и ожидает аутентификации на сервере `primary`:

**client/init-script.sh**

```bash
kinit -k -t "/keytab/$CLIENT_PRINCIPAL.keytab" $CLIENT_PRINCIPAL

until pg_isready -U badatabase -d badatabase -h primary.badatabase.local; do
    echo 'Waiting auth...'
    sleep 1
done

echo 'Kerberos authentication success'
```

### Соединение по TLS

Для соединения по TLS сгенерируем сертификаты:

```bash
cd ssl
./gen.sh
```

Добавим строку защищенных соединений:

**primary/primary.env**

```bash
POSTGRES_DB=badatabase
POSTGRES_USER=badatabase
POSTGRES_PASSWORD=badatabase
#POSTGRES_HOST_AUTH_METHOD="            gss
POSTGRES_HOST_AUTH_METHOD="            scram-sha-256
host       replication  all 0.0.0.0/0  md5
hostssl    all          all all        cert
hostgssenc all          all all        gss include_realm=0 krb_realm=BADATABASE.LOCAL
"
```

и установим соответствующие конфигурации для `postgres.conf`:

**docker-compose.yml**

```yaml
...
primary:
  ...
  command: |
    postgres
    -c ssl=on
    -c ssl_cert_file='/ssl/postgres.crt'
    -c ssl_key_file='/ssl/postgres.key'
    ...
```

Пробуем аутентифицироваться с хостовой машины:

```bash
psql -U badatabase -d badatabase -h localhost -p 5454
```

```
Password for user badatabase: 
psql (15.5 (Debian 15.5-0+deb12u1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

badatabase=# 
```

