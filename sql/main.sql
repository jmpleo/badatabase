CREATE TABLE IF NOT EXISTS badeviceinfo (
    deviceid VARCHAR(16) PRIMARY KEY,
    devicename VARCHAR(32) NOT NULL UNIQUE,
    adcfreq INTEGER NOT NULL,
    startdiscret INTEGER NOT NULL
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
    average INTEGER NOT NULL,
    freqstart DOUBLE PRECISION NOT NULL,
    freqstep DOUBLE PRECISION NOT NULL,
    freqstop DOUBLE PRECISION NOT NULL,
    sensorlength INTEGER NOT NULL,
    sensorpointlength INTEGER NOT NULL,
    sensorstartpoint INTEGER NOT NULL,
    sensorendpoint INTEGER NOT NULL,
    cwatt INTEGER NOT NULL,
    adpgain INTEGER NOT NULL,
    pulsegain INTEGER NOT NULL,
    pulselength INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sensorslines (
    lineid SERIAL PRIMARY KEY,
    sensorid INTEGER NOT NULL, -- REFERENCES sensors(sensorid),
    linename VARCHAR(32) NOT NULL,
    linefullname VARCHAR(128) NOT NULL DEFAULT '',
    linetype INTEGER NOT NULL,
    startpoint INTEGER NOT NULL,
    endpoint INTEGER NOT NULL,
    direct INTEGER NOT NULL,
    lengthpoints INTEGER NOT NULL,
    lengthmeters DOUBLE PRECISION NOT NULL,
    mhztemp20 DOUBLE PRECISION NOT NULL,
    tempcoeff DOUBLE PRECISION NOT NULL,
    defcoeff DOUBLE PRECISION NOT NULL,
    auxlineid INTEGER NOT NULL,

    CONSTRAINT linename_unique UNIQUE(sensorid, linename)
);

CREATE TABLE IF NOT EXISTS sweepdatalorenz (
    sweepid SERIAL PRIMARY KEY,
    sweeptime TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    sensorid INTEGER NOT NULL, -- REFERENCES sensors(sensorid),
    sensorname VARCHAR(32) NOT NULL, -- REFERENCES sensors(sensorname),
    average INTEGER NOT NULL,
    freqstart DOUBLE PRECISION NOT NULL,
    freqstep DOUBLE PRECISION NOT NULL,
    freqstop DOUBLE PRECISION NOT NULL,
    sensorlength INTEGER NOT NULL,
    sensorpointlength INTEGER NOT NULL,
    sensorstartpoint INTEGER NOT NULL,
    sensorendpoint INTEGER NOT NULL,
    cwatt INTEGER NOT NULL,
    adpgain INTEGER NOT NULL,
    pulsegain INTEGER NOT NULL,
    pulselength INTEGER NOT NULL,
    datalorenz REAL[] NOT NULL,
    shc REAL NOT NULL,
    datalorenz_w REAL[] NOT NULL,
    datalorenz_y0 REAL[] NOT NULL,
    datalorenz_a REAL[] NOT NULL,
    datalorenz_err REAL[] NOT NULL
);

CREATE TABLE IF NOT EXISTS zones (
    zoneid SERIAL PRIMARY KEY,
    extzoneid INTEGER NOT NULL DEFAULT 0,
    lineid INTEGER NOT NULL, -- REFERENCES sensorslines(lineid),
    sensorid INTEGER NOT NULL, -- REFERENCES sensors(sensorid),
    deviceid VARCHAR(16) NOT NULL, -- REFERENCES badeviceinfo(deviceid),
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

CREATE ROLE admin WITH LOGIN PASSWORD 'admin';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

CREATE ROLE labler WITH LOGIN PASSWORD 'labler';
GRANT SELECT, INSERT, UPDATE ON sensorslines TO labler;
GRANT SELECT, INSERT, UPDATE ON zones TO labler;

CREATE ROLE auditor WITH LOGIN PASSWORD 'auditor';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor;
ALTER TABLE sweepdatalorenz
ADD COLUMN IF NOT EXISTS shc REAL NOT NULL DEFAULT 0;

ALTER TABLE sensors
DROP CONSTRAINT IF EXISTS sensorname_unique;
ALTER TABLE sensors
ADD CONSTRAINT sensorname_unique UNIQUE(sensorname);

ALTER TABLE sensorslines
DROP CONSTRAINT IF EXISTS linename_unique;
ALTER TABLE sensorslines
ADD CONSTRAINT linename_unique UNIQUE(sensorid, linename);

ALTER TABLE zones
DROP CONSTRAINT IF EXISTS zonename_unique;
ALTER TABLE zones
ADD CONSTRAINT zonename_unique UNIQUE(lineid, zonename);
ALTER TABLE zones
ADD COLUMN IF NOT EXISTS extzoneid INTEGER NOT NULL DEFAULT 0;
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
  p_sensorpointlength INTEGER,
  p_cwatt INTEGER,
  p_adpgain INTEGER,
  p_pulsegain INTEGER,
  p_pulselength INTEGER,
  p_sensorid INTEGER DEFAULT NULL,
  p_sensorfname VARCHAR(128) DEFAULT '',
  p_comment VARCHAR(256) DEFAULT '',
  p_sensorstartpoint INTEGER DEFAULT 0
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
            sensorpointlength = p_sensorpointlength,
            sensorstartpoint = p_sensorstartpoint,
            sensorendpoint = p_sensorendpoint,
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
        sensorpointlength,
        sensorstartpoint,
        sensorendpoint,
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
        p_sensorpointlength,
        p_sensorstartpoint,
        p_sensorendpoint,
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
        sensorpointlength = p_sensorpointlength,
        sensorstartpoint = p_sensorstartpoint,
        sensorendpoint = p_sensorendpoint,
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
        p_sensorpointlength => s.sensorpointlength,
        p_cwatt => s.cwatt,
        p_adpgain => s.adpgain,
        p_pulsegain => s.pulsegain,
        p_pulselength => s.pulselength,
        p_sensorid => s.sensorid,
        p_sensorfname => s.sensorfname,
        p_comment => s.comment,
        p_sensorstartpoint => s.sensorstartpoint
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
  p_sensorpointlength INTEGER,
  p_cwatt INTEGER,
  p_adpgain INTEGER,
  p_pulsegain INTEGER,
  p_pulselength INTEGER,
  p_sensorid INTEGER DEFAULT NULL,
  p_sensorfname VARCHAR(128) DEFAULT '',
  p_comment VARCHAR(256) DEFAULT '',
  p_sensorstartpoint INTEGER DEFAULT 0
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
        sensorpointlength,
        sensorstartpoint,
        sensorendpoint,
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
        p_sensorpointlength,
        p_sensorstartpoint,
        p_sensorendpoint,
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
        p_sensorpointlength => s.sensorpointlength,
        p_cwatt => s.cwatt,
        p_adpgain => s.adpgain,
        p_pulsegain => s.pulsegain,
        p_pulselength => s.pulselength,
        p_sensorid => s.sensorid,
        p_sensorfname => s.sensorfname,
        p_comment => s.comment,
        p_sensorstartpoint => s.sensorstartpoint
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
  p_sensorpointlength INTEGER,
  p_sensorstartpoint INTEGER,
  p_sensorendpoint INTEGER,
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
        sensorpointlength,
        sensorstartpoint,
        sensorendpoint,
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
        p_sensorpointlength,
        p_sensorstartpoint,
        p_sensorendpoint,
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
  p_sensorpointlength INTEGER,
  p_sensorstartpoint INTEGER,
  p_sensorendpoint INTEGER,
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
            sensorpointlength = p_sensorpointlength,
            sensorstartpoint = p_sensorstartpoint,
            sensorendpoint = p_sensorendpoint,
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
        sensorpointlength,
        sensorstartpoint,
        sensorendpoint,
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
        p_sensorpointlength,
        p_sensorstartpoint,
        p_sensorendpoint,
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
            sensorpointlength = p_sensorpointlength,
            sensorstartpoint = p_sensorstartpoint,
            sensorendpoint = p_sensorendpoint,
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

DROP FUNCTION IF EXISTS cur_select_sensorslines(REFCURSOR, INTEGER);
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


DROP FUNCTION IF EXISTS cur_select_sensors(REFCURSOR);
CREATE OR REPLACE FUNCTION cur_select_sensors (cur_name REFCURSOR)
RETURNS REFCURSOR AS $$
BEGIN
    OPEN cur_name FOR SELECT * FROM sensors;
    RETURN cur_name;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS cur_select_sensors(REFCURSOR, INTEGER);
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


DROP FUNCTION IF EXISTS cur_select_sweepdatalorenz (REFCURSOR, INTEGER, TIMESTAMP);
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


