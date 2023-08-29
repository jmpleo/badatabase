/*
 * Функция осуществляет жесткую вставку зоны
 * обновляя запись по первичному ключу и ограничению zonename_unique
 */
CREATE OR REPLACE FUNCTION insert_zones_with_update (
  p_lineid INTEGER,
  p_sensorid INTEGER,
  p_deviceid VARCHAR(16),
  p_zonename VARCHAR(32),
  p_zonetype INTEGER,
  p_direct INTEGER,
  p_startinareax DOUBLE PRECISION,
  p_startinareay DOUBLE PRECISION,
  p_endinareax DOUBLE PRECISION,
  p_endinareay DOUBLE PRECISION,
  p_lengthzoneinarea DOUBLE PRECISION,
  p_startinline DOUBLE PRECISION,
  p_endinline DOUBLE PRECISION,
  p_lengthinline DOUBLE PRECISION,
  p_zoneid INTEGER DEFAULT NULL,
  p_extzoneid INTEGER DEFAULT 0,
  p_zonefullname VARCHAR(128) DEFAULT ''
)
RETURNS INTEGER AS $$
DECLARE
  r_zoneid INTEGER;
BEGIN
    IF p_zoneid IS NOT NULL THEN
        UPDATE zones
        SET
            extzoneid = p_extzoneid,
            lineid = p_lineid,
            sensorid = p_sensorid,
            deviceid = p_deviceid,
            zonename = p_zonename,
            zonefullname = p_zonefullname,
            zonetype = p_zonetype,
            direct = p_direct,
            startinareax = p_startinareax,
            startinareay = p_startinareay,
            endinareax = p_endinareax,
            endinareay = p_endinareay,
            lengthzoneinarea = p_lengthzoneinarea,
            startinline = p_startinline,
            endinline = p_endinline,
            lengthinline = p_lengthinline
        WHERE
            zoneid = p_zoneid
        RETURNING
            zoneid INTO r_zoneid;

        IF FOUND THEN
            RETURN r_zoneid;
        END IF;
    END IF;

    INSERT INTO zones (
        extzoneid,
        lineid,
        sensorid,
        deviceid,
        zonename,
        zonefullname,
        zonetype,
        direct,
        startinareax,
        startinareay,
        endinareax,
        endinareay,
        lengthzoneinarea,
        startinline,
        endinline,
        lengthinline
    ) VALUES (
        p_extzoneid,
        p_lineid,
        p_sensorid,
        p_deviceid,
        p_zonename,
        p_zonefullname,
        p_zonetype,
        p_direct,
        p_startinareax,
        p_startinareay,
        p_endinareax,
        p_endinareay,
        p_lengthzoneinarea,
        p_startinline,
        p_endinline,
        p_lengthinline
    )
    ON CONFLICT (lineid, zonename)
        DO UPDATE
        SET
            extzoneid = p_extzoneid,
            lineid = p_lineid,
            sensorid = p_sensorid,
            deviceid = p_deviceid,
            zonename = p_zonename,
            zonefullname = p_zonefullname,
            zonetype = p_zonetype,
            direct = p_direct,
            startinareax = p_startinareax,
            startinareay = p_startinareay,
            endinareax = p_endinareax,
            endinareay = p_endinareay,
            lengthzoneinarea = p_lengthzoneinarea,
            startinline = p_startinline,
            endinline = p_endinline,
            lengthinline = p_lengthinline
    RETURNING
        zoneid INTO r_zoneid;
    RETURN r_zoneid;
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_zones_with_update ( z zones )
RETURNS INTEGER AS $$
DECLARE
  r_zoneid INTEGER;
BEGIN
    SELECT insert_zones_with_update (
        p_zoneid = z.zoneid,
        p_extzoneid = z.extzoneid,
        p_lineid = z.lineid,
        p_sensorid = z.sensorid,
        p_deviceid = z.deviceid,
        p_zonename = z.zonename,
        p_zonefullname = z.zonefullname,
        p_zonetype = z.zonetype,
        p_direct = z.direct,
        p_startinareax = z.startinareax,
        p_startinareay = z.startinareay,
        p_endinareax = z.endinareax,
        p_endinareay = z.endinareay,
        p_lengthzoneinarea = z.lengthzoneinarea,
        p_startinline = z.startinline,
        p_endinline = z.endinline,
        p_lengthinline = z.lengthinline
    ) INTO r_zoneid;
    RETURN r_zoneid;
END;
$$ LANGUAGE plpgsql;

/*
 * Функция осуществляет мягкую вставку зоны
 * не обновляя запись по первичному ключу и ограничению zonename_unique
 * если такая уже имеется
 */
CREATE OR REPLACE FUNCTION insert_zones_without_update (
  p_lineid INTEGER,
  p_sensorid INTEGER,
  p_deviceid VARCHAR(16),
  p_zonename VARCHAR(32),
  p_zonetype INTEGER,
  p_direct INTEGER,
  p_startinareax DOUBLE PRECISION,
  p_startinareay DOUBLE PRECISION,
  p_endinareax DOUBLE PRECISION,
  p_endinareay DOUBLE PRECISION,
  p_lengthzoneinarea DOUBLE PRECISION,
  p_startinline DOUBLE PRECISION,
  p_endinline DOUBLE PRECISION,
  p_lengthinline DOUBLE PRECISION,
  p_zoneid INTEGER DEFAULT NULL,
  p_extzoneid INTEGER DEFAULT 0,
  p_zonefullname VARCHAR(128) DEFAULT ''
)
RETURNS INTEGER AS $$
DECLARE
  r_zoneid INTEGER;
BEGIN
    IF p_zoneid IS NOT NULL THEN
        SELECT zoneid FROM zones WHERE zoneid = p_zoneid INTO r_zoneid;
        IF FOUND THEN
            RETURN r_zoneid;
        END IF;
    END IF;

    INSERT INTO zones (
        extzoneid,
        lineid,
        sensorid,
        deviceid,
        zonename,
        zonefullname,
        zonetype,
        direct,
        startinareax,
        startinareay,
        endinareax,
        endinareay,
        lengthzoneinarea,
        startinline,
        endinline,
        lengthinline
    ) VALUES (
        p_extzoneid,
        p_lineid,
        p_sensorid,
        p_deviceid,
        p_zonename,
        p_zonefullname,
        p_zonetype,
        p_direct,
        p_startinareax,
        p_startinareay,
        p_endinareax,
        p_endinareay,
        p_lengthzoneinarea,
        p_startinline,
        p_endinline,
        p_lengthinline
    )
    ON CONFLICT
        DO NOTHING
    RETURNING
        zoneid INTO r_zoneid;
    RETURN r_zoneid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_zones_without_update ( z zones )
RETURNS INTEGER AS $$
DECLARE
    r_zoneid INTEGER;
BEGIN
    SELECT insert_zones_without_update (
        p_zoneid => z.zoneid,
        p_extzoneid => z.extzoneid,
        p_lineid => z.lineid,
        p_sensorid => z.sensorid,
        p_deviceid => z.deviceid,
        p_zonename => z.zonename,
        p_zonefullname => z.zonefullname,
        p_zonetype => z.zonetype,
        p_direct => z.direct,
        p_startinareax => z.startinareax,
        p_startinareay => z.startinareay,
        p_endinareax => z.endinareax,
        p_endinareay => z.endinareay,
        p_lengthzoneinarea => z.lengthzoneinarea,
        p_startinline => z.startinline,
        p_endinline => z.endinline,
        p_lengthinline => z.lengthinline
    ) INTO r_zoneid;
    RETURN r_zoneid;
END;
$$ LANGUAGE plpgsql;

