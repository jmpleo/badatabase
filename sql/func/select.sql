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


