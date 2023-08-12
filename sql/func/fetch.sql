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


