# Отчет: Построение защищенных СУБД

@jmpleo @1193221

---

## Описание предметной области

Анализ характеристик оптоволоконного кабеля: бриллюэновский анализатор спектра частот.

## Сущности

- `badeviceinfo` - Конфигурация устройства бриллюэновского анализатора.
- `sensors` - Характеристики сенсора устройства.
- `sensorslines` - Параметры отрезка снятых сенсором характеристик.
- `zones` - Параметры определенной зона на участке линии.
- `sweepdatalorenz` - Непосредственно характеристики (частоты) снятые сенсором. 

## ER-диаграмма

![diagl](/home/j/proj/badatabase/diagl.png)

## Ролевая модель безопасности

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

## Тщательный контроль доступа (RLS)

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

## Политика аудита

