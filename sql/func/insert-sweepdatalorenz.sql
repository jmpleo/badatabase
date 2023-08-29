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




