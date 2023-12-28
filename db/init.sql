-- init.sql --


CREATE EXTENSION pgcrypto;




CREATE TABLE IF NOT EXISTS badeviceinfo (
    deviceid VARCHAR(16) PRIMARY KEY,
    devicename VARCHAR(32) NOT NULL UNIQUE,
    adcfreq INTEGER NOT NULL CHECK (adcfreq >= 0),
    startdiscret INTEGER NOT NULL CHECK (startdiscret >= 0)
);


CREATE TABLE IF NOT EXISTS sensors (
    sensorid SERIAL PRIMARY KEY,
    sensorname VARCHAR(32) NOT NULL UNIQUE,
    sensorfname VARCHAR(128) NOT NULL DEFAULT '',
    flagsensoron BOOLEAN NOT NULL,
    flagusingswith BOOLEAN NOT NULL,
    extracmdscript VARCHAR(128) NOT NULL,
    switchsensorname VARCHAR(64) NOT NULL,
    comment VARCHAR(256) NOT NULL DEFAULT '',
    average INTEGER NOT NULL CHECK (average >= 0),
    freqstart DOUBLE PRECISION NOT NULL CHECK (freqstart >= 0),
    freqstep DOUBLE PRECISION NOT NULL CHECK (freqstep >= 0),
    freqstop DOUBLE PRECISION NOT NULL,
    sensorlength INTEGER NOT NULL,
    sensorstartpoint INTEGER CHECK (sensorstartpoint >= 0),
    sensorendpoint INTEGER CHECK (sensorendpoint >= 0),
    sensorpointlength INTEGER CHECK (sensorpointlength >= 0),
    cwatt INTEGER NOT NULL,
    adpgain INTEGER NOT NULL,
    pulsegain INTEGER NOT NULL,
    pulselength INTEGER NOT NULL
);


CREATE TABLE IF NOT EXISTS sensorslines (
    lineid SERIAL PRIMARY KEY,
    sensorid INTEGER NOT NULL REFERENCES sensors(sensorid),
    linename VARCHAR(32) NOT NULL,
    linefullname VARCHAR(128) NOT NULL DEFAULT '',
    linetype INTEGER NOT NULL,
    startpoint INTEGER NOT NULL CHECK (startpoint >= 0),
    endpoint INTEGER NOT NULL CHECK (endpoint >= 0),
    direct INTEGER NOT NULL,
    lengthpoints INTEGER NOT NULL CHECK (lengthpoints >= 0),
    lengthmeters DOUBLE PRECISION NOT NULL CHECK (lengthmeters >= 0),
    mhztemp20 DOUBLE PRECISION NOT NULL,
    tempcoeff DOUBLE PRECISION NOT NULL,
    defcoeff DOUBLE PRECISION NOT NULL,
    auxlineid INTEGER NOT NULL,

    CONSTRAINT linename_unique UNIQUE (sensorid, linename)
);


CREATE TABLE IF NOT EXISTS sweepdatalorenz (
    sweepid SERIAL PRIMARY KEY,
    sweeptime TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    sensorid INTEGER NOT NULL REFERENCES sensors(sensorid),
    sensorname VARCHAR(32) NOT NULL REFERENCES sensors(sensorname),
    average INTEGER NOT NULL,
    freqstart DOUBLE PRECISION NOT NULL CHECK (freqstart >= 0),
    freqstep DOUBLE PRECISION NOT NULL CHECK (freqstep >= 0),
    freqstop DOUBLE PRECISION NOT NULL,
    sensorlength INTEGER NOT NULL CHECK (sensorlength >= 0),
    sensorpointlength INTEGER NOT NULL CHECK (sensorpointlength >= 0),
    sensorstartpoint INTEGER NOT NULL CHECK (sensorstartpoint >= 0),
    sensorendpoint INTEGER NOT NULL CHECK (sensorendpoint >= 0),
    cwatt INTEGER NOT NULL,
    adpgain INTEGER NOT NULL,
    pulsegain INTEGER NOT NULL,
    pulselength INTEGER NOT NULL, datalorenz REAL[] NOT NULL,
    shc REAL NOT NULL,
    datalorenz_w REAL[] NOT NULL,
    datalorenz_y0 REAL[] NOT NULL,
    datalorenz_a REAL[] NOT NULL,
    datalorenz_err REAL[] NOT NULL,

    CONSTRAINT sweepdatalorenz_unique UNIQUE(sensorid, sweeptime),
    CONSTRAINT array_length CHECK (
        array_length(datalorenz, 1) = array_length(datalorenz_w, 1)
        AND array_length(datalorenz, 1) = array_length(datalorenz_y0, 1)
        AND array_length(datalorenz, 1) = array_length(datalorenz_a, 1)
        AND array_length(datalorenz, 1) = array_length(datalorenz_err, 1)
    )
);


CREATE TABLE IF NOT EXISTS zones (
    zoneid SERIAL PRIMARY KEY,
    extzoneid INTEGER NOT NULL DEFAULT 0,
    lineid INTEGER NOT NULL REFERENCES sensorslines(lineid),
    sensorid INTEGER NOT NULL REFERENCES sensors(sensorid),
    deviceid VARCHAR(16) NOT NULL REFERENCES badeviceinfo(deviceid),
    zonename VARCHAR(32) NOT NULL,
    zonefullname VARCHAR(128) NOT NULL DEFAULT '',
    zonetype INTEGER NOT NULL,
    direct INTEGER NOT NULL,
    startinareax DOUBLE PRECISION NOT NULL,
    startinareay DOUBLE PRECISION NOT NULL,
    endinareax DOUBLE PRECISION NOT NULL,
    endinareay DOUBLE PRECISION NOT NULL,
    lengthzoneinarea DOUBLE PRECISION NOT NULL,
    startinline DOUBLE PRECISION NOT NULL,
    endinline DOUBLE PRECISION NOT NULL,
    lengthinline DOUBLE PRECISION NOT NULL,

    CONSTRAINT zonename_unique UNIQUE(lineid, zonename)
);




CREATE TABLE labelers (
    labelerid SERIAL PRIMARY KEY,
    labelername VARCHAR(50) NOT NULL UNIQUE,
    timestamp TIMESTAMP DEFAULT now()
);


CREATE TABLE labelers_keys (
    keyid SERIAL PRIMARY KEY,
    key TEXT NOT NULL DEFAULT '',
    labelername VARCHAR(50) NOT NULL REFERENCES labelers(labelername),
    labelerid INTEGER REFERENCES labelers(labelerid)
);


CREATE TABLE labelers_notes (
    noteid SERIAL PRIMARY KEY,
    note TEXT NOT NULL DEFAULT '',
    labelerid INTEGER REFERENCES labelers(labelerid)
);



DO $$
BEGIN
    IF NOT EXISTS ( SELECT 1 FROM pg_type WHERE typname = 'dml_type') THEN
        CREATE TYPE dml_type AS ENUM ('INSERT', 'UPDATE', 'DELETE');
    END IF;
END
$$;


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
    PRIMARY KEY (zone_id, dml_type, dml_timestamp)
);




--DROP FUNCTION IF EXISTS fetch_sensorslines (REFCURSOR);
CREATE OR REPLACE FUNCTION fetch_sensorslines (cur REFCURSOR)
RETURNS SETOF sensorslines AS $$
DECLARE
    l sensorslines;
BEGIN
    FETCH NEXT IN cur INTO l;
    IF FOUND THEN
        RETURN NEXT l;
    ELSE
        RETURN;
    END IF;
END;
$$ LANGUAGE plpgsql;


--DROP FUNCTION IF EXISTS fetch_sensors (REFCURSOR);
CREATE OR REPLACE FUNCTION fetch_sensors (cur REFCURSOR)
RETURNS SETOF sensors AS $$
DECLARE
    s sensors;
BEGIN
    FETCH NEXT IN cur INTO s;
    IF FOUND THEN
        RETURN NEXT s;
    ELSE
        RETURN;
    END IF;
END;
$$ LANGUAGE plpgsql;


--DROP FUNCTION IF EXISTS fetch_zones (REFCURSOR);
CREATE OR REPLACE FUNCTION fetch_zones (cur REFCURSOR)
RETURNS SETOF zones AS $$
DECLARE
    z zones;
BEGIN
    FETCH NEXT IN cur INTO z;
    IF FOUND THEN
        RETURN NEXT z;
    ELSE
        RETURN;
    END IF;
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION notes_encryption_handle()
RETURNS TRIGGER AS $$
BEGIN
    IF
        CURRENT_USER NOT IN (SELECT labelername FROM labelers_keys)
    THEN
        RAISE EXCEPTION 'User have not a key';
    END IF;

    IF
        CURRENT_USER != NEW.labelername
    THEN
        RAISE EXCEPTION 'Permission denied to update data';
    END IF;

    NEW.notes := pgp_sym_encrypt(
        NEW.notes, (
            SELECT
                key
            FROM
                labelers_keys
            WHERE
                labelername = CURRENT_USER
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION zones_audit_log_trigger_handle()
RETURNS TRIGGER AS $$
BEGIN
   IF (TG_OP = 'INSERT') THEN
        INSERT INTO zones_audit_log (
            zone_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            NEW.zoneid,
            null,
            to_jsonb(NEW),
            'INSERT',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN NEW;

   ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO zones_audit_log (
            zone_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            NEW.zoneid,
            to_jsonb(OLD),
            to_jsonb(NEW),
            'UPDATE',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN NEW;

   ELSIF (TG_OP = 'DELETE') THEN
       INSERT INTO zones_audit_log (
            zone_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            OLD.zoneid,
            to_jsonb(OLD),
            null,
            'DELETE',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN OLD;

   END IF;

END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sensorslines_audit_log_trigger_handle()
RETURNS TRIGGER AS $$
BEGIN
   IF (TG_OP = 'INSERT') THEN
        INSERT INTO sensorslines_audit_log (
            line_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            NEW.lineid,
            null,
            to_jsonb(NEW),
            'INSERT',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN NEW;

   ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO sensorslines_audit_log (
            line_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            NEW.lineid,
            to_jsonb(OLD),
            to_jsonb(NEW),
            'UPDATE',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN NEW;

   ELSIF (TG_OP = 'DELETE') THEN
       INSERT INTO sensorslines_audit_log (
            line_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            OLD.lineid,
            to_jsonb(OLD),
            null,
            'DELETE',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN OLD;

   END IF;

END;
$$
LANGUAGE plpgsql;



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
/*
 *  Фунция осуществляет мягкую вставку устройства
 *  Если устройство с первичным ключом существует,
 *  то вставляемое устройство игнорируется
 */
--DROP FUNCTION IF EXISTS insert_badeviceinfo_without_update (VARCHAR(16), VARCHAR(32), INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION insert_badeviceinfo_without_update (
    p_deviceid VARCHAR(16),
    p_devicename VARCHAR(32),
    p_adcfreq INTEGER,
    p_startdiscret INTEGER
)
RETURNS VARCHAR(16) AS $$
DECLARE
  r_deviceid VARCHAR(16);
BEGIN
  INSERT INTO badeviceinfo (
    deviceid,
    devicename,
    adcfreq,
    startdiscret
  ) VALUES (
    p_deviceid,
    p_devicename,
    p_adcfreq,
    p_startdiscret
  )
  ON CONFLICT
    DO NOTHING
  RETURNING
    deviceid INTO r_deviceid;
  RETURN r_deviceid;
END;
$$ LANGUAGE plpgsql;


--DROP FUNCTION IF EXISTS insert_badeviceinfo_without_update ( badeviceinfo );
CREATE OR REPLACE FUNCTION insert_badeviceinfo_without_update ( d badeviceinfo )
RETURNS VARCHAR(16) AS $$
DECLARE
  r_deviceid VARCHAR(16);
BEGIN
  INSERT INTO badeviceinfo (
    deviceid,
    devicename,
    adcfreq,
    startdiscret
  ) VALUES (
    d.deviceid,
    d.devicename,
    d.adcfreq,
    d.startdiscret
  )
  ON CONFLICT
    DO NOTHING
  RETURNING
    deviceid INTO r_deviceid;
  RETURN r_deviceid;
END;
$$ LANGUAGE plpgsql;



/*
 * Функция осуществляет жесткую вставку устройства,
 * затирая уже существующую информацю об устройстве
 */
--DROP FUNCTION IF EXISTS insert_badeviceinfo_with_update (VARCHAR(16), VARCHAR(32), INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION insert_badeviceinfo_with_update (
    p_deviceid VARCHAR(16),
    p_devicename VARCHAR(32),
    p_adcfreq INTEGER,
    p_startdiscret INTEGER
)
RETURNS VARCHAR(16) AS $$
DECLARE
  r_deviceid VARCHAR(16);
BEGIN
  DELETE FROM badeviceinfo WHERE deviceid = p_deviceid;
  INSERT INTO badeviceinfo (
    deviceid,
    devicename,
    adcfreq,
    startdiscret
  ) VALUES (
    p_deviceid,
    p_devicename,
    p_adcfreq,
    p_startdiscret
  )
  ON CONFLICT (devicename)
    DO UPDATE
      SET
        deviceid = p_deviceid,
        devicename = p_devicename,
        adcfreq = p_adcfreq,
        startdiscret = p_startdiscret
  RETURNING
    deviceid INTO r_deviceid;
  RETURN r_deviceid;
END;
$$ LANGUAGE plpgsql;


--DROP FUNCTION IF EXISTS insert_badeviceinfo_with_update ( badeviceinfo );
CREATE OR REPLACE FUNCTION insert_badeviceinfo_with_update ( d badeviceinfo )
RETURNS VARCHAR(16) AS $$
DECLARE
  r_deviceid VARCHAR(16);
BEGIN
  DELETE FROM badeviceinfo WHERE deviceid = d.deviceid;
  INSERT INTO badeviceinfo (
    deviceid,
    devicename,
    adcfreq,
    startdiscret
  ) VALUES (
    d.deviceid,
    d.devicename,
    d.adcfreq,
    d.startdiscret
  )
  ON CONFLICT (devicename)
    DO UPDATE
      SET
        deviceid = d.deviceid,
        devicename = d.devicename,
        adcfreq = d.adcfreq,
        startdiscret = d.startdiscret
  RETURNING
    deviceid INTO r_deviceid;
  RETURN r_deviceid;
END;
$$ LANGUAGE plpgsql;


/*
 * Функция осуществляет жесткую вставку сенсора,
 * затирая существующий сенсор по первичному ключу
 */
CREATE OR REPLACE FUNCTION insert_sensors_with_update (
  p_sensorname VARCHAR(32),
  p_flagsensoron BOOLEAN,
  p_flagusingswith BOOLEAN,
  p_extracmdscript VARCHAR(128),
  p_switchsensorname VARCHAR(64),
  p_average INTEGER,
  p_freqstart DOUBLE PRECISION,
  p_freqstep DOUBLE PRECISION,
  p_freqstop DOUBLE PRECISION,
  p_sensorlength INTEGER,
  p_cwatt INTEGER,
  p_adpgain INTEGER,
  p_pulsegain INTEGER,
  p_pulselength INTEGER,
  p_sensorstartpoint INTEGER DEFAULT NULL,
  p_sensorendpoint INTEGER DEFAULT NULL,
  p_sensorpointlength INTEGER DEFAULT NULL,
  p_sensorid INTEGER DEFAULT NULL,
  p_sensorfname VARCHAR(128) DEFAULT '',
  p_comment VARCHAR(256) DEFAULT ''
) RETURNS INT AS $$
DECLARE
    r_sensorid INT;
BEGIN
    IF p_sensorid IS NOT NULL THEN
        UPDATE sensors
        SET
            sensorname = p_sensorname,
            sensorfname = p_sensorfname,
            flagsensoron = p_flagsensoron,
            flagusingswith = p_flagusingswith,
            extracmdscript = p_extracmdscript,
            switchsensorname = p_switchsensorname,
            comment = p_comment,
            average = p_average,
            freqstart = p_freqstart,
            freqstep = p_freqstep,
            freqstop = p_freqstop,
            sensorlength = p_sensorlength,
            sensorstartpoint = p_sensorstartpoint,
            sensorendpoint = p_sensorendpoint,
            sensorpointlength = p_sensorpointlength,
            cwatt = p_cwatt,
            adpgain = p_adpgain,
            pulsegain = p_pulsegain,
            pulselength = p_pulselength
        WHERE
            sensorid = p_sensorid
        RETURNING
            sensorid INTO r_sensorid;

        IF FOUND THEN
            RETURN r_sensorid;
        END IF;
    END IF;

    INSERT INTO sensors (
        sensorname,
        sensorfname,
        flagsensoron,
        flagusingswith,
        extracmdscript,
        switchsensorname,
        comment,
        average,
        freqstart,
        freqstep,
        freqstop,
        sensorlength,
        sensorstartpoint,
        sensorendpoint,
        sensorpointlength,
        cwatt,
        adpgain,
        pulsegain,
        pulselength
    ) VALUES (
        p_sensorname,
        p_sensorfname,
        p_flagsensoron,
        p_flagusingswith,
        p_extracmdscript,
        p_switchsensorname,
        p_comment,
        p_average,
        p_freqstart,
        p_freqstep,
        p_freqstop,
        p_sensorlength,
        p_sensorstartpoint,
        p_sensorendpoint,
        p_sensorpointlength,
        p_cwatt,
        p_adpgain,
        p_pulsegain,
        p_pulselength
    )
    ON CONFLICT (sensorname)
    DO UPDATE SET
        sensorname = p_sensorname,
        sensorfname = p_sensorfname,
        flagsensoron = p_flagsensoron,
        flagusingswith = p_flagusingswith,
        extracmdscript = p_extracmdscript,
        switchsensorname = p_switchsensorname,
        comment = p_comment,
        average = p_average,
        freqstart = p_freqstart,
        freqstep = p_freqstep,
        freqstop = p_freqstop,
        sensorlength = p_sensorlength,
        sensorstartpoint = p_sensorstartpoint,
        sensorendpoint = p_sensorendpoint,
        sensorpointlength = p_sensorpointlength,
        cwatt = p_cwatt,
        adpgain = p_adpgain,
        pulsegain = p_pulsegain,
        pulselength = p_pulselength
    RETURNING
        sensorid INTO r_sensorid;
    RETURN
        r_sensorid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_sensors_with_update ( s sensors )
RETURNS INT AS $$
DECLARE
    r_sensorid INT;
BEGIN
    SELECT insert_sensors_with_update (
        p_sensorname => s.sensorname,
        p_flagsensoron => s.flagsensoron,
        p_flagusingswith => s.flagusingswith,
        p_extracmdscript => s.extracmdscript,
        p_switchsensorname => s.switchsensorname,
        p_average => s.average,
        p_freqstart => s.freqstart,
        p_freqstep => s.freqstep,
        p_freqstop => s.freqstop,
        p_sensorlength => s.sensorlength,
        p_sensorstartpoint => s.sensorstartpoint,
        p_sensorendpoint => s.sensorendpoint,
        p_sensorpointlength => s.sensorpointlength,
        p_cwatt => s.cwatt,
        p_adpgain => s.adpgain,
        p_pulsegain => s.pulsegain,
        p_pulselength => s.pulselength,
        p_sensorid => s.sensorid,
        p_sensorfname => s.sensorfname,
        p_comment => s.comment
    ) INTO r_sensorid;
    RETURN r_sensorid;
END;
$$ LANGUAGE plpgsql;


/*
 * Функция осуществляет мягкую вставку сенсора,
 * не затирая существующий сенсор по первичному ключу
 */
CREATE OR REPLACE FUNCTION insert_sensors_without_update(
  p_sensorname VARCHAR(32),
  p_flagsensoron BOOLEAN,
  p_flagusingswith BOOLEAN,
  p_extracmdscript VARCHAR(128),
  p_switchsensorname VARCHAR(64),
  p_average INTEGER,
  p_freqstart DOUBLE PRECISION,
  p_freqstep DOUBLE PRECISION,
  p_freqstop DOUBLE PRECISION,
  p_sensorlength INTEGER,
  p_cwatt INTEGER,
  p_adpgain INTEGER,
  p_pulsegain INTEGER,
  p_pulselength INTEGER,
  p_sensorstartpoint INTEGER DEFAULT NULL,
  p_sensorendpoint INTEGER DEFAULT NULL,
  p_sensorpointlength INTEGER DEFAULT NULL,
  p_sensorid INTEGER DEFAULT NULL,
  p_sensorfname VARCHAR(128) DEFAULT '',
  p_comment VARCHAR(256) DEFAULT ''
) RETURNS INT AS $$
DECLARE
    r_sensorid INT;
BEGIN
    IF p_sensorid IS NOT NULL THEN
        SELECT sensorid FROM sensors WHERE sensorid = p_sensorid INTO r_sensorid;
        IF FOUND THEN
            RETURN r_sensorid;
        END IF;
    END IF;

    INSERT INTO sensors (
        sensorname,
        sensorfname,
        flagsensoron,
        flagusingswith,
        extracmdscript,
        switchsensorname,
        comment,
        average,
        freqstart,
        freqstep,
        freqstop,
        sensorlength,
        sensorstartpoint,
        sensorendpoint,
        sensorpointlength,
        cwatt,
        adpgain,
        pulsegain,
        pulselength
    ) VALUES (
        p_sensorname,
        p_sensorfname,
        p_flagsensoron,
        p_flagusingswith,
        p_extracmdscript,
        p_switchsensorname,
        p_comment,
        p_average,
        p_freqstart,
        p_freqstep,
        p_freqstop,
        p_sensorlength,
        p_sensorstartpoint,
        p_sensorendpoint,
        p_sensorpointlength,
        p_cwatt,
        p_adpgain,
        p_pulsegain,
        p_pulselength
    )
    ON CONFLICT (sensorname)
        DO NOTHING
    RETURNING
        sensorid INTO r_sensorid;
    RETURN
        r_sensorid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_sensors_without_update ( s sensors )
RETURNS INT AS $$
DECLARE
    r_sensorid INT;
BEGIN
    SELECT insert_sensors_without_update (
        p_sensorname => s.sensorname,
        p_flagsensoron => s.flagsensoron,
        p_flagusingswith => s.flagusingswith,
        p_extracmdscript => s.extracmdscript,
        p_switchsensorname => s.switchsensorname,
        p_average => s.average,
        p_freqstart => s.freqstart,
        p_freqstep => s.freqstep,
        p_freqstop => s.freqstop,
        p_sensorlength => s.sensorlength,
        p_sensorstartpoint => s.sensorstartpoint,
        p_sensorendpoint => s.sensorendpoint,
        p_sensorpointlength => s.sensorpointlength,
        p_cwatt => s.cwatt,
        p_adpgain => s.adpgain,
        p_pulsegain => s.pulsegain,
        p_pulselength => s.pulselength,
        p_sensorid => s.sensorid,
        p_sensorfname => s.sensorfname,
        p_comment => s.comment
    ) INTO r_sensorid;
    RETURN r_sensorid;
END;
$$ LANGUAGE plpgsql;


/*
 * Функция осуществляет жесткую вставку линии
 * обновляя запись по первичному ключу и ограничению linename_unique
 */
CREATE OR REPLACE FUNCTION insert_sensorslines_with_update (
    p_sensorid INTEGER,
    p_linename VARCHAR(32),
    p_linetype INTEGER,
    p_startpoint INTEGER,
    p_endpoint INTEGER,
    p_direct INTEGER,
    p_lengthpoints INTEGER,
    p_lengthmeters DOUBLE PRECISION,
    p_mhztemp20 DOUBLE PRECISION,
    p_tempcoeff DOUBLE PRECISION,
    p_defcoeff DOUBLE PRECISION,
    p_auxlineid INTEGER,
    p_lineid INTEGER DEFAULT NULL,
    p_linefullname VARCHAR(128) DEFAULT ''
)
RETURNS INTEGER AS $$
DECLARE
    r_lineid INTEGER;
BEGIN
    IF p_lineid IS NOT NULL THEN
        UPDATE sensorslines
        SET
            sensorid = p_sensorid,
            linename = p_linename,
            linefullname = p_linefullname,
            linetype = p_linetype,
            startpoint = p_startpoint,
            endpoint = p_endpoint,
            direct = p_direct,
            lengthpoints = p_lengthpoints,
            lengthmeters = p_lengthmeters,
            mhztemp20 = p_mhztemp20,
            tempcoeff = p_tempcoeff,
            defcoeff = p_defcoeff,
            auxlineid = p_auxlineid
        WHERE
            lineid = p_lineid
        RETURNING
            lineid INTO r_lineid;

        IF FOUND THEN
            RETURN r_lineid;
        END IF;
    END IF;

    INSERT INTO sensorslines (
        sensorid,
        linename,
        linefullname,
        linetype,
        startpoint,
        endpoint,
        direct,
        lengthpoints,
        lengthmeters,
        mhztemp20,
        tempcoeff,
        defcoeff,
        auxlineid
    ) VALUES (
        p_sensorid,
        p_linename,
        p_linefullname,
        p_linetype,
        p_startpoint,
        p_endpoint,
        p_direct,
        p_lengthpoints,
        p_lengthmeters,
        p_mhztemp20,
        p_tempcoeff,
        p_defcoeff,
        p_auxlineid
    )
    ON CONFLICT (sensorid, linename)
    DO UPDATE
        SET
            sensorid = p_sensorid,
            linename = p_linename,
            linefullname = p_linefullname,
            linetype = p_linetype,
            startpoint = p_startpoint,
            endpoint = p_endpoint,
            direct = p_direct,
            lengthpoints = p_lengthpoints,
            lengthmeters = p_lengthmeters,
            mhztemp20 = p_mhztemp20,
            tempcoeff = p_tempcoeff,
            defcoeff = p_defcoeff,
            auxlineid = p_auxlineid
    RETURNING
        lineid INTO r_lineid;
    RETURN r_lineid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_sensorslines_with_update ( l sensorslines )
RETURNS INTEGER AS $$
DECLARE
    r_lineid INTEGER;
BEGIN
    SELECT insert_sensorslines_with_update (
        --p_lineid => l.lineid,
        p_sensorid => l.sensorid,
        p_linename => l.linename,
        p_linefullname => l.linefullname,
        p_linetype => l.linetype,
        p_startpoint => l.startpoint,
        p_endpoint => l.endpoint,
        p_direct => l.direct,
        p_lengthpoints => l.lengthpoints,
        p_lengthmeters => l.lengthmeters,
        p_mhztemp20 => l.mhztemp20,
        p_tempcoeff => l.tempcoeff,
        p_defcoeff => l.defcoeff,
        p_auxlineid => l.auxlineid
    ) INTO r_lineid;
    RETURN r_lineid;
END;
$$ LANGUAGE plpgsql;

/*
 * Функция осуществляет мягкую вставку линии
 * не обновляя запись по первичному ключу и ограничению linename_unique
 * если такая уже имеется
 */
CREATE OR REPLACE FUNCTION insert_sensorslines_without_update (
    p_sensorid INTEGER,
    p_linename VARCHAR(32),
    p_linetype INTEGER,
    p_startpoint INTEGER,
    p_endpoint INTEGER,
    p_direct INTEGER,
    p_lengthpoints INTEGER,
    p_lengthmeters DOUBLE PRECISION,
    p_mhztemp20 DOUBLE PRECISION,
    p_tempcoeff DOUBLE PRECISION,
    p_defcoeff DOUBLE PRECISION,
    p_auxlineid INTEGER,
    p_lineid INTEGER DEFAULT NULL,
    p_linefullname VARCHAR(128) DEFAULT ''
)
RETURNS INTEGER AS $$
DECLARE
    r_lineid INTEGER;
BEGIN
    IF p_lineid IS NOT NULL THEN
        SELECT lineid FROM sensorslines WHERE lineid = p_lineid INTO r_lineid;
        IF FOUND THEN
            RETURN r_lineid;
        END IF;
    END IF;

    INSERT INTO sensorslines (
        sensorid,
        linename,
        linefullname,
        linetype,
        startpoint,
        endpoint,
        direct,
        lengthpoints,
        lengthmeters,
        mhztemp20,
        tempcoeff,
        defcoeff,
        auxlineid
    ) VALUES (
        p_sensorid,
        p_linename,
        p_linefullname,
        p_linetype,
        p_startpoint,
        p_endpoint,
        p_direct,
        p_lengthpoints,
        p_lengthmeters,
        p_mhztemp20,
        p_tempcoeff,
        p_defcoeff,
        p_auxlineid
    )
    ON CONFLICT
        DO NOTHING
    RETURNING
        lineid INTO r_lineid;
    RETURN r_lineid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_sensorslines_without_update ( l sensorslines )
RETURNS INTEGER AS $$
DECLARE
    r_lineid INTEGER;
BEGIN
    SELECT insert_sensorslines_without_update (
        --p_lineid => l.lineid,
        p_sensorid => l.sensorid,
        p_linename => l.linename,
        p_linefullname => l.linefullname,
        p_linetype => l.linetype,
        p_startpoint => l.startpoint,
        p_endpoint => l.endpoint,
        p_direct => l.direct,
        p_lengthpoints => l.lengthpoints,
        p_lengthmeters => l.lengthmeters,
        p_mhztemp20 => l.mhztemp20,
        p_tempcoeff => l.tempcoeff,
        p_defcoeff => l.defcoeff,
        p_auxlineid => l.auxlineid
    ) INTO r_lineid;
    RETURN r_lineid;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION insert_sweepdatalorenz_without_update (
  p_sweeptime TIMESTAMP WITHOUT TIME ZONE,
  p_sensorid INTEGER,
  p_sensorname VARCHAR(32),
  p_average INTEGER,
  p_freqstart DOUBLE PRECISION,
  p_freqstep DOUBLE PRECISION,
  p_freqstop DOUBLE PRECISION,
  p_sensorlength INTEGER,
  p_sensorstartpoint INTEGER,
  p_sensorendpoint INTEGER,
  p_sensorpointlength INTEGER,
  p_cwatt INTEGER,
  p_adpgain INTEGER,
  p_pulsegain INTEGER,
  p_pulselength INTEGER,
  p_datalorenz REAL[],
  p_shc REAL,
  p_datalorenz_w REAL[],
  p_datalorenz_y0 REAL[],
  p_datalorenz_a REAL[],
  p_datalorenz_err REAL[],
  p_sweepid INTEGER DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
  r_sweepid INTEGER;
BEGIN
    IF p_sweepid IS NOT NULL THEN
        SELECT sweepid FROM sweepdatalorenz WHERE sweepid = p_sweepid INTO r_sweepid;
        IF FOUND THEN
            RETURN r_sweepid;
        END IF;
    END IF;

    INSERT INTO sweepdatalorenz (
        sweeptime,
        sensorid,
        sensorname,
        average,
        freqstart,
        freqstep,
        freqstop,
        sensorlength,
        sensorstartpoint,
        sensorendpoint,
        sensorpointlength,
        cwatt,
        adpgain,
        pulsegain,
        pulselength,
        datalorenz,
        shc,
        datalorenz_w,
        datalorenz_y0,
        datalorenz_a,
        datalorenz_err
    ) VALUES (
        p_sweeptime,
        p_sensorid,
        p_sensorname,
        p_average,
        p_freqstart,
        p_freqstep,
        p_freqstop,
        p_sensorlength,
        p_sensorstartpoint,
        p_sensorendpoint,
        p_sensorpointlength,
        p_cwatt,
        p_adpgain,
        p_pulsegain,
        p_pulselength,
        p_datalorenz,
        p_shc,
        p_datalorenz_w,
        p_datalorenz_y0,
        p_datalorenz_a,
        p_datalorenz_err
    )
    ON CONFLICT
        DO NOTHING
    RETURNING
        sweepid INTO r_sweepid;
    RETURN r_sweepid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_sweepdatalorenz_with_update (
  p_sweeptime TIMESTAMP WITHOUT TIME ZONE,
  p_sensorid INTEGER,
  p_sensorname VARCHAR(32),
  p_average INTEGER,
  p_freqstart DOUBLE PRECISION,
  p_freqstep DOUBLE PRECISION,
  p_freqstop DOUBLE PRECISION,
  p_sensorlength INTEGER,
  p_sensorstartpoint INTEGER,
  p_sensorendpoint INTEGER,
  p_sensorpointlength INTEGER,
  p_cwatt INTEGER,
  p_adpgain INTEGER,
  p_pulsegain INTEGER,
  p_pulselength INTEGER,
  p_datalorenz REAL[],
  p_shc REAL,
  p_datalorenz_w REAL[],
  p_datalorenz_y0 REAL[],
  p_datalorenz_a REAL[],
  p_datalorenz_err REAL[],
  p_sweepid INTEGER DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    r_sweepid INTEGER;
BEGIN
    IF p_sweepid IS NOT NULL THEN
        UPDATE sweepdatalorenz
        SET
            sweeptime = p_sweeptime,
            sensorid = p_sensorid,
            sensorname = p_sensorname,
            average = p_average,
            freqstart = p_freqstart,
            freqstep = p_freqstep,
            freqstop = p_freqstop,
            sensorlength = p_sensorlength,
            sensorstartpoint = p_sensorstartpoint,
            sensorendpoint = p_sensorendpoint,
            sensorpointlength = p_sensorpointlength,
            cwatt = p_cwatt,
            adpgain = p_adpgain,
            pulsegain = p_pulsegain,
            pulselength = p_pulselength,
            datalorenz = p_datalorenz,
            shc = p_shc,
            datalorenz_w = p_datalorenz_w,
            datalorenz_y0 = p_datalorenz_y0,
            datalorenz_a = p_datalorenz_a,
            datalorenz_err = p_datalorenz_err
        WHERE
            sweepid = p_sweepid
        RETURNING
            sweepid INTO r_sweepid;

        IF FOUND THEN
            RETURN r_sweepid;
        END IF;
    END IF;


    INSERT INTO sweepdatalorenz (
        sweeptime,
        sensorid,
        sensorname,
        average,
        freqstart,
        freqstep,
        freqstop,
        sensorlength,
        sensorstartpoint,
        sensorendpoint,
        sensorpointlength,
        cwatt,
        adpgain,
        pulsegain,
        pulselength,
        datalorenz,
        shc,
        datalorenz_w,
        datalorenz_y0,
        datalorenz_a,
        datalorenz_err
    ) VALUES (
        p_sweeptime,
        p_sensorid,
        p_sensorname,
        p_average,
        p_freqstart,
        p_freqstep,
        p_freqstop,
        p_sensorlength,
        p_sensorstartpoint,
        p_sensorendpoint,
        p_sensorpointlength,
        p_cwatt,
        p_adpgain,
        p_pulsegain,
        p_pulselength,
        p_datalorenz,
        p_shc,
        p_datalorenz_w,
        p_datalorenz_y0,
        p_datalorenz_a,
        p_datalorenz_err
    )
    ON CONFLICT
    DO UPDATE
        SET
            sweeptime = p_sweeptime,
            sensorid = p_sensorid,
            sensorname = p_sensorname,
            average = p_average,
            freqstart = p_freqstart,
            freqstep = p_freqstep,
            freqstop = p_freqstop,
            sensorlength = p_sensorlength,
            sensorstartpoint = p_sensorstartpoint,
            sensorendpoint = p_sensorendpoint,
            sensorpointlength = p_sensorpointlength,
            cwatt = p_cwatt,
            adpgain = p_adpgain,
            pulsegain = p_pulsegain,
            pulselength = p_pulselength,
            datalorenz = p_datalorenz,
            shc = p_shc,
            datalorenz_w = p_datalorenz_w,
            datalorenz_y0 = p_datalorenz_y0,
            datalorenz_a = p_datalorenz_a,
            datalorenz_err = p_datalorenz_err
    RETURNING
        sweepid INTO r_sweepid;
    RETURN r_sweepid;
END;
$$ LANGUAGE plpgsql;




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
        --p_zoneid => z.zoneid,
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
        --p_zoneid => z.zoneid,
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

-- DROP FUNCTION IF EXISTS cur_select_sensorslines(REFCURSOR, INTEGER);
CREATE OR REPLACE FUNCTION cur_select_sensorslines (
    cur_name REFCURSOR,
    p_sensorid INTEGER DEFAULT NULL
)
RETURNS REFCURSOR AS $$
BEGIN
    IF p_sensorid IS NOT NULL THEN
        OPEN cur_name FOR SELECT * FROM sensorslines WHERE sensorid = p_sensorid;
    ELSE
        OPEN cur_name FOR SELECT * FROM sensorslines;
    END IF;
    RETURN cur_name;
END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS cur_select_sensors(REFCURSOR);
CREATE OR REPLACE FUNCTION cur_select_sensors (cur_name REFCURSOR)
RETURNS REFCURSOR AS $$
BEGIN
    OPEN cur_name FOR SELECT * FROM sensors;
    RETURN cur_name;
END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS cur_select_sensors(REFCURSOR, INTEGER);
CREATE OR REPLACE FUNCTION cur_select_zones (
    cur_name REFCURSOR,
    p_sensorid INTEGER DEFAULT NULL
)
RETURNS REFCURSOR AS $$
BEGIN
    IF p_sensorid IS NOT NULL THEN
        OPEN cur_name FOR SELECT * FROM zones WHERE sensorid = p_sensorid;
    ELSE
        OPEN cur_name FOR SELECT * FROM zones;
    END IF;
    RETURN cur_name;
END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS cur_select_sweepdatalorenz (REFCURSOR, INTEGER, TIMESTAMP);
CREATE OR REPLACE FUNCTION cur_select_sweepdatalorenz (
    cur_name REFCURSOR,
    p_sensorid INTEGER DEFAULT NULL,
    p_sweeptime TIMESTAMP DEFAULT NULL
)
RETURNS REFCURSOR AS $$
BEGIN
    IF p_sensorid IS NOT NULL AND p_sweeptime IS NOT NULL THEN
        OPEN cur_name FOR
        SELECT *
        FROM sweepdatalorenz
        WHERE sensorid = p_sensorid AND sweeptime = p_sweeptime;

    ELSIF p_sensorid IS NOT NULL THEN
        OPEN cur_name FOR
        SELECT *
        FROM sweepdatalorenz
        WHERE sensorid = p_sensorid;

    ELSIF p_sweeptime IS NOT NULL THEN
        OPEN cur_name FOR
        SELECT *
        FROM sweepdatalorenz
        WHERE sweeptime = p_sweeptime;

    ELSE
        OPEN cur_name FOR SELECT * FROM sweepdatalorenz;
    END IF;

    RETURN cur_name;
END;
$$ LANGUAGE plpgsql;




CREATE TRIGGER notes_encryption_trigger
BEFORE
    INSERT OR UPDATE ON labelers_notes
FOR
    EACH ROW
EXECUTE
    FUNCTION notes_encryption_handle();




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


CREATE OR REPLACE TRIGGER sensor_points_trigger
    BEFORE
        INSERT ON sensors
    FOR
        EACH ROW
    EXECUTE FUNCTION
        sensor_points_handle();
CREATE ROLE admin WITH LOGIN PASSWORD 'admin';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

CREATE ROLE zones_labeler WITH LOGIN PASSWORD 'zones_labeler';
GRANT INSERT ON zones TO zones_labeler;
GRANT SELECT ON TABLE labelers TO zones_labeler;

CREATE ROLE sensorslines_labeler WITH LOGIN PASSWORD 'sensorslines_labeler';
GRANT INSERT ON sensorslines TO sensorslines_labeler;
GRANT SELECT ON TABLE labelers TO sensorslines_labeler;

CREATE ROLE auditor WITH LOGIN PASSWORD 'auditor';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor;

CREATE USER zones_labeler_sensor_1 WITH PASSWORD 'zones_labeler_sensor_1';
GRANT zones_labeler to zones_labeler_sensor_1;

CREATE USER sensorslines_labeler_sensor_1 WITH PASSWORD 'sensorslines_labeler_sensor_1';
GRANT sensorslines_labeler to sensorslines_labeler_sensor_1;

CREATE USER auditor_sensor_1 WITH PASSWORD 'auditor_sensor_1';
GRANT auditor to auditor_sensor_1;

CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator';

ALTER TABLE sensorslines ENABLE ROW LEVEL SECURITY;
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE labelers_keys ENABLE ROW LEVEL SECURITY;

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

CREATE POLICY sensorslines_labeler_view_only_self_key ON labelers_keys FOR
    SELECT TO sensorslines_labeler USING (labelername = CURRENT_USER);

CREATE POLICY zones_labeler_view_only_self_key ON labelers_keys FOR
    SELECT TO zones_labeler USING (labelername = CURRENT_USER);
SELECT pg_create_physical_replication_slot('replication_slot');
