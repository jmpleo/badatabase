/*
CREATE OR REPLACE FUNCTION update_sensor_line (
    p_lineid INTEGER,
    p_linename VARCHAR(32) DEFAULT NULL,
    p_linefullname VARCHAR(128) DEFAULT NULL,
    p_linetype INTEGER DEFAULT NULL,
    p_startpoint INTEGER DEFAULT NULL,
    p_endpoint INTEGER DEFAULT NULL,
    p_direct INTEGER DEFAULT NULL,
    p_lengthpoints INTEGER DEFAULT NULL,
    p_lengthmeters DOUBLE PRECISION DEFAULT NULL,
    p_mhztemp20 DOUBLE PRECISION DEFAULT NULL,
    p_tempcoeff DOUBLE PRECISION DEFAULT NULL,
    p_defcoeff DOUBLE PRECISION DEFAULT NULL,
    p_auxlineid INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE sensorslines
        SET
            linename = COALESCE(p_linename, linename),
            linefullname = COALESCE(p_linefullname, linefullname),
            linetype = COALESCE(p_linetype, linetype),
            startpoint = COALESCE(p_startpoint, startpoint),
            endpoint = COALESCE(p_endpoint, endpoint),
            direct = COALESCE(p_direct, direct),
            lengthpoints = COALESCE(p_lengthpoints, lengthpoints),
            lengthmeters = COALESCE(p_lengthmeters, lengthmeters),
            mhztemp20 = COALESCE(p_mhztemp20, mhztemp20),
            tempcoeff = COALESCE(p_tempcoeff, tempcoeff),
            defcoeff = COALESCE(p_defcoeff, defcoeff),
            auxlineid = COALESCE(p_auxlineid, auxlineid)
    WHERE lineid = p_lineid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_sensor(
    p_sensorid INTEGER,
    p_sensorname VARCHAR(32) DEFAULT NULL,
    p_sensorfname VARCHAR(128) DEFAULT NULL,
    p_flagsensoron BOOLEAN DEFAULT NULL,
    p_flagusingswith BOOLEAN DEFAULT NULL,
    p_extracmdscript VARCHAR(128) DEFAULT NULL,
    p_switchsensorname VARCHAR(64) DEFAULT NULL,
    p_comment VARCHAR(256) DEFAULT NULL,
    p_average INTEGER DEFAULT NULL,
    p_freqstart DOUBLE PRECISION DEFAULT NULL,
    p_freqstep DOUBLE PRECISION DEFAULT NULL,
    p_freqstop DOUBLE PRECISION DEFAULT NULL,
    p_sensorlength INTEGER DEFAULT NULL,
    p_sensorpointlength INTEGER DEFAULT NULL,
    p_sensorstartpoint INTEGER DEFAULT NULL,
    p_sensorendpoint INTEGER DEFAULT NULL,
    p_cwatt INTEGER DEFAULT NULL,
    p_adpgain INTEGER DEFAULT NULL,
    p_pulsegain INTEGER DEFAULT NULL,
    p_pulselength INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE sensors
        SET
            sensorname = COALESCE(p_sensorname, sensorname),
            sensorfname = coalesce(p_sensorfname, sensorfname),
            flagsensoron = COALESCE(p_flagsensoron, flagsensoron),
            flagusingswith = COALESCE(p_flagusingswith, flagusingswith),
            extracmdscript = COALESCE(p_extracmdscript, extracmdscript),
            switchsensorname = COALESCE(p_switchsensorname, switchsensorname),
            comment = COALESCE(p_comment, comment),
            average = COALESCE(p_average, average),
            freqstart = COALESCE(p_freqstart, freqstart),
            freqstep = COALESCE(p_freqstep, freqstep),
            freqstop = COALESCE(p_freqstop, freqstop),
            sensorlength = COALESCE(p_sensorlength, sensorlength),
            sensorpointlength = COALESCE(p_sensorpointlength, sensorpointlength),
            sensorstartpoint = COALESCE(p_sensorstartpoint, sensorstartpoint),
            sensorendpoint = COALESCE(p_sensorendpoint, sensorendpoint),
            cwatt = COALESCE(p_cwatt, cwatt),
            adpgain = COALESCE(p_adpgain, adpgain),
            pulsegain = COALESCE(p_pulsegain, pulsegain),
            pulselength = COALESCE(p_pulselength, pulselength)
    WHERE sensorid = p_sensorid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_zone(
    p_zoneid INTEGER,
    p_lineid INTEGER DEFAULT NULL,
    p_sensorid INTEGER DEFAULT NULL,
    p_deviceid VARCHAR(16) DEFAULT NULL,
    p_zonename VARCHAR(32) DEFAULT NULL,
    p_zonefullname VARCHAR(128) DEFAULT NULL,
    p_zonetype INTEGER DEFAULT NULL,
    p_direct INTEGER DEFAULT NULL,
    p_startinareax DOUBLE PRECISION DEFAULT NULL,
    p_startinareay DOUBLE PRECISION DEFAULT NULL,
    p_endinareax DOUBLE PRECISION DEFAULT NULL,
    p_endinareay DOUBLE PRECISION DEFAULT NULL,
    p_lengthzoneinarea DOUBLE PRECISION DEFAULT NULL,
    p_startinline DOUBLE PRECISION DEFAULT NULL,
    p_endinline DOUBLE PRECISION DEFAULT NULL,
    p_lengthinline DOUBLE PRECISION DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE zones
        SET
            lineid = COALESCE(p_lineid, lineid),
            sensorid = COALESCE(p_sensorid, sensorid),
            deviceid = COALESCE(p_deviceid, deviceid),
            zonename = COALESCE(p_zonename, zonename),
            zonefullname = COALESCE(p_zonefullname, zonefullname),
            zonetype = COALESCE(p_zonetype, zonetype),
            direct = COALESCE(p_direct, direct),
            startinareax = COALESCE(p_startinareax, startinareax),
            startinareay = COALESCE(p_startinareay, startinareay),
            endinareax = COALESCE(p_endinareax, endinareax),
            endinareay = COALESCE(p_endinareay, endinareay),
            lengthzoneinarea = COALESCE(p_lengthzoneinarea, lengthzoneinarea),
            startinline = COALESCE(p_startinline, startinline),
            endinline = COALESCE(p_endinline, endinline),
            lengthinline = COALESCE(p_lengthinline, lengthinline)
    WHERE zoneid = p_zoneid;
END;
$$ LANGUAGE plpgsql;
*/
