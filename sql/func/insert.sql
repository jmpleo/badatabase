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
)
RETURNS INTEGER AS $$
DECLARE
  r_sensorid INTEGER;
BEGIN

  IF p_sensorid IS NULL THEN
    p_sensorid := nextval('sensors_sensorid_seq');
  ELSE
    DELETE FROM sensors WHERE sensorid = p_sensorid;
  END IF;

  INSERT INTO sensors (
    sensorid,
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
    p_sensorid,
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
    DO UPDATE
      SET
        sensorid = p_sensorid,
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
  RETURN r_sensorid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_sensors_with_update ( s sensors )
RETURNS INTEGER AS $$
DECLARE
  r_sensorid INTEGER;
BEGIN

  IF s.sensorid IS NULL THEN
    s.sensorid := nextval('sensors_sensorid_seq');
  ELSE
    DELETE FROM sensors WHERE sensorid = s.sensorid;
  END IF;

  INSERT INTO sensors (
    sensorid,
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
    s.sensorid,
    s.sensorname,
    s.sensorfname,
    s.flagsensoron,
    s.flagusingswith,
    s.extracmdscript,
    s.switchsensorname,
    s.comment,
    s.average,
    s.freqstart,
    s.freqstep,
    s.freqstop,
    s.sensorlength,
    s.sensorpointlength,
    s.sensorstartpoint,
    s.sensorendpoint,
    s.cwatt,
    s.adpgain,
    s.pulsegain,
    s.pulselength
  )
  ON CONFLICT (sensorname)
    DO UPDATE
      SET
        sensorid = s.sensorid,
        sensorname = s.sensorname,
        sensorfname = s.sensorfname,
        flagsensoron = s.flagsensoron,
        flagusingswith = s.flagusingswith,
        extracmdscript = s.extracmdscript,
        switchsensorname = s.switchsensorname,
        comment = s.comment,
        average = s.average,
        freqstart = s.freqstart,
        freqstep = s.freqstep,
        freqstop = s.freqstop,
        sensorlength = s.sensorlength,
        sensorpointlength = s.sensorpointlength,
        sensorstartpoint = s.sensorstartpoint,
        sensorendpoint = s.sensorendpoint,
        cwatt = s.cwatt,
        adpgain = s.adpgain,
        pulsegain = s.pulsegain,
        pulselength = s.pulselength
  RETURNING
    sensorid INTO r_sensorid;
  RETURN r_sensorid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_sensors_without_update (
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
  p_sensorstartpoint INTEGER,
  p_sensorendpoint INTEGER,
  p_cwatt INTEGER,
  p_adpgain INTEGER,
  p_pulsegain INTEGER,
  p_pulselength INTEGER,
  p_sensorid INTEGER DEFAULT NULL,
  p_sensorfname VARCHAR(128) DEFAULT '',
  p_comment VARCHAR(256) DEFAULT ''
)
RETURNS INTEGER AS $$
DECLARE
  r_sensorid INTEGER;
BEGIN
  INSERT INTO sensors (
    sensorid,
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
    (CASE WHEN p_sensorid IS NOT NULL THEN p_sensorid ELSE nextval('sensors_sensorid_seq') END),
    p_sensorname,
    p_sensorfname,
    p_flagsensoron, p_flagusingswith,
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
  ON CONFLICT
    DO NOTHING
  RETURNING
    sensorid INTO r_sensorid;
  RETURN r_sensorid;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION insert_sensors_without_update ( s sensors )
RETURNS INTEGER AS $$
DECLARE
  r_sensorid INTEGER;
BEGIN

  s.sensorid:= (
    CASE WHEN s.sensorid IS NOT NULL THEN
      s.sensorid
    ELSE
      nextval('sensors_sensorid_seq')
    END
  );

  INSERT INTO sensors (
    sensorid,
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
    s.sensorid,
    s.sensorname,
    s.sensorfname,
    s.flagsensoron, p_flagusingswith,
    s.extracmdscript,
    s.switchsensorname,
    s.comment,
    s.average,
    s.freqstart,
    s.freqstep,
    s.freqstop,
    s.sensorlength,
    s.sensorpointlength,
    s.sensorstartpoint,
    s.sensorendpoint,
    s.cwatt,
    s.adpgain,
    s.pulsegain,
    s.pulselength
  )
  ON CONFLICT
    DO NOTHING
  RETURNING
    sensorid INTO r_sensorid;
  RETURN r_sensorid;
END;
$$ LANGUAGE plpgsql;


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

  IF EXISTS(SELECT 1 FROM sensorslines WHERE sensorid = p_sensorid AND linename = p_linename)
  OR EXISTS(SELECT 1 FROM sensorslines WHERE lineid = p_lineid) THEN
    RAISE NOTICE 'Линия linename(%) сенсора id(%) была перезаписана', p_linename, p_sensorid;
  END IF;

  IF p_lineid IS NULL THEN
    p_lineid := nextval('sensorslines_lineid_seq');
  ELSE
    DELETE FROM sensorslines WHERE lineid = p_lineid;
  END IF;

  INSERT INTO sensorslines (
    lineid,
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
    p_lineid,
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
        lineid = p_lineid,
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

  IF EXISTS(SELECT 1 FROM sensorslines WHERE sensorid = l.sensorid AND linename = l.linename)
  OR EXISTS(SELECT 1 FROM sensorslines WHERE lineid = l.lineid) THEN
    RAISE NOTICE 'Линия linename(%) сенсора id(%) была перезаписана', l.linename, l.sensorid;
  END IF;

  IF l.lineid IS NULL THEN
    l.lineid := nextval('sensorslines_lineid_seq');
  ELSE
    DELETE FROM sensorslines WHERE lineid = l.lineid;
  END IF;

  INSERT INTO sensorslines (
    lineid,
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
    l.lineid,
    l.sensorid,
    l.linename,
    l.linefullname,
    l.linetype,
    l.startpoint,
    l.endpoint,
    l.direct,
    l.lengthpoints,
    l.lengthmeters,
    l.mhztemp20,
    l.tempcoeff,
    l.defcoeff,
    l.auxlineid
  )
  ON CONFLICT (sensorid, linename)
    DO UPDATE
      SET
        lineid = l.lineid,
        sensorid = l.sensorid,
        linename = l.linename,
        linefullname = l.linefullname,
        linetype = l.linetype,
        startpoint = l.startpoint,
        endpoint = l.endpoint,
        direct = l.direct,
        lengthpoints = l.lengthpoints,
        lengthmeters = l.lengthmeters,
        mhztemp20 = l.mhztemp20,
        tempcoeff = l.tempcoeff,
        defcoeff = l.defcoeff,
        auxlineid = l.auxlineid
  RETURNING
    lineid INTO r_lineid;
  RETURN r_lineid;
END;
$$ LANGUAGE plpgsql;


/*
 * Function try insert line with primary key
 * if primary key exists then do nothing
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

  IF EXISTS(SELECT 1 FROM sensorslines WHERE sensorid = p_sensorid AND linename = p_linename)
  OR EXISTS(SELECT 1 FROM sensorslines WHERE lineid = p_lineid) THEN
    RAISE NOTICE 'Линия linename(%) сенсора id(%) не была перезаписана', p_linename, p_sensorid;
  END IF;

  p_lineid := (
    CASE WHEN p_lineid IS NOT NULL THEN
      p_lineid
    ELSE
      nextval('sensorslines_lineid_seq')
    END
  );
  INSERT INTO sensorslines (
    lineid,
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
    p_lineid,
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

  IF EXISTS(SELECT 1 FROM sensorslines WHERE sensorid = l.sensorid AND linename = l.linename)
  OR EXISTS(SELECT 1 FROM sensorslines WHERE lineid = l.lineid) THEN
    RAISE NOTICE 'Линия linename(%) сенсора id(%) не была перезаписана', l.linename, l.sensorid;
  END IF;

  l.lineid := (
    CASE WHEN l.lineid IS NOT NULL THEN
      l.lineid
    ELSE
      nextval('sensorslines_lineid_seq')
    END
  );
  INSERT INTO sensorslines (
    lineid,
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
    l.lineid,
    l.sensorid,
    l.linename,
    l.linefullname,
    l.linetype,
    l.startpoint,
    l.endpoint,
    l.direct,
    l.lengthpoints,
    l.lengthmeters,
    l.mhztemp20,
    l.tempcoeff,
    l.defcoeff,
    l.auxlineid
  )
  ON CONFLICT
    DO NOTHING
  RETURNING
    lineid INTO r_lineid;
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

  p_sweepid := (
    CASE WHEN p_sweepid IS NOT NULL THEN
      p_sweepid
    ELSE
      nextval('sweepdatalorenz_sweepid_seq')
    END
  );

  INSERT INTO sweepdatalorenz (
    sweepid,
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
    p_sweepid,
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

  IF p_sweeptime IS NULL THEN
    p_sweepid := nextval('sweepdatalorenz_sweepid_seq');
  ELSE
    DELETE FROM sweepdatalorenz WHERE sweepid = p_sweepid;
  END IF;

  INSERT INTO sweepdatalorenz (
    sweepid,
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
    p_sweepid,
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
        sweepid = p_sweepid,
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

  IF EXISTS(SELECT 1 FROM zones WHERE lineid = p_lineid AND zonename = p_zonename)
  OR EXISTS(SELECT 1 FROM zones WHERE zoneid = p_zoneid) THEN
    RAISE NOTICE 'Зона zonename(%) линии lineid(%) не была перезаписана', p_zonename, p_lineid;
  END IF;

  p_zoneid := (
    CASE WHEN p_zoneid IS NULL OR EXISTS(SELECT 1 FROM zones WHERE zoneid = p_zoneid) THEN
      nextval('zones_zoneid_seq')
    ELSE
      p_zoneid
    END
  );
  INSERT INTO zones (
    zoneid,
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
    p_zoneid,
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

  IF EXISTS(SELECT 1 FROM zones WHERE lineid = z.lineid AND zonename = z.zonename)
  OR EXISTS(SELECT 1 FROM zones WHERE zoneid = z.zoneid) THEN
    RAISE NOTICE 'Зона zonename(%) линии lineid(%) не была перезаписана', z.zonename, z.lineid;
  END IF;

  z.zoneid := (
    CASE WHEN z.zoneid IS NULL OR EXISTS(SELECT 1 FROM zones WHERE zoneid = z.zoneid) THEN
      nextval('zones_zoneid_seq')
    ELSE
      z.zoneid
    END
  );
  INSERT INTO zones (
    zoneid,
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
    z.zoneid,
    z.extzoneid,
    z.lineid,
    z.sensorid,
    z.deviceid,
    z.zonename,
    z.zonefullname,
    z.zonetype,
    z.direct,
    z.startinareax,
    z.startinareay,
    z.endinareax,
    z.endinareay,
    z.lengthzoneinarea,
    z.startinline,
    z.endinline,
    z.lengthinline
  )
  ON CONFLICT
    DO NOTHING
  RETURNING
    zoneid INTO r_zoneid;
  RETURN r_zoneid;
END;
$$ LANGUAGE plpgsql;


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


  IF EXISTS(SELECT 1 FROM zones WHERE lineid = p_lineid AND zonename = p_zonename)
  OR EXISTS(SELECT 1 FROM zones WHERE zoneid = p_zoneid) THEN
    RAISE NOTICE 'Зона zonename(%) линии lineid(%) была перезаписана', p_zonename, p_lineid;
  END IF;

  IF p_zoneid IS NULL THEN
    p_zoneid := nextval('zones_zoneid_seq');
  ELSE
    DELETE FROM zones WHERE zoneid = p_zoneid;
  END IF;

  INSERT INTO zones (
    zoneid,
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
    p_zoneid,
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
        zoneid = p_zoneid,
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

  IF EXISTS(SELECT 1 FROM zones WHERE lineid = z.lineid AND zonename = z.zonename)
  OR EXISTS(SELECT 1 FROM zones WHERE zoneid = z.zoneid) THEN
    RAISE NOTICE 'Зона zonename(%) линии lineid(%) была перезаписана', z.zonename, z.lineid;
  END IF;

  IF z.zoneid IS NULL THEN
    z.zoneid := nextval('zones_zoneid_seq');
  ELSE
    DELETE FROM zones WHERE zoneid = z.zoneid;
  END IF;

  INSERT INTO zones (
    zoneid,
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
    z.zoneid,
    z.extzoneid,
    z.lineid,
    z.sensorid,
    z.deviceid,
    z.zonename,
    z.zonefullname,
    z.zonetype,
    z.direct,
    z.startinareax,
    z.startinareay,
    z.endinareax,
    z.endinareay,
    z.lengthzoneinarea,
    z.startinline,
    z.endinline,
    z.lengthinline
  )
  ON CONFLICT (lineid, zonename)
    DO UPDATE
      SET
        zoneid = z.zoneid,
        extzoneid = z.extzoneid,
        lineid = z.lineid,
        sensorid = z.sensorid,
        deviceid = z.deviceid,
        zonename = z.zonename,
        zonefullname = z.zonefullname,
        zonetype = z.zonetype,
        direct = z.direct,
        startinareax = z.startinareax,
        startinareay = z.startinareay,
        endinareax = z.endinareax,
        endinareay = z.endinareay,
        lengthzoneinarea = z.lengthzoneinarea,
        startinline = z.startinline,
        endinline = z.endinline,
        lengthinline = z.lengthinline
  RETURNING
    zoneid INTO r_zoneid;
  RETURN r_zoneid;
END;

$$ LANGUAGE plpgsql;

