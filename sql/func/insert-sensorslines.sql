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
        p_lineid => l.lineid,
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
        p_auxlineid => p_auxlineid
    );
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
        p_lineid => l.lineid,
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
        auxlineid => l.auxlineid
    ) INTO r_lineid;
    RETURN r_lineid;
END;
$$ LANGUAGE plpgsql;



