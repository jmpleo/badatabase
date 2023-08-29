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
        WHERE sensorid = p_sensorid
        RETURNING sensorid INTO r_sensorid;

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
    RETURNING sensorid INTO r_sensorid;
    RETURN r_sensorid;
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
    RETURNING sensorid INTO r_sensorid;
    RETURN r_sensorid;
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


