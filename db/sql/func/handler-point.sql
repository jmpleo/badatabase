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
