CREATE OR REPLACE TRIGGER sensor_points_trigger
    BEFORE
        INSERT ON sensors
    FOR
        EACH ROW
    EXECUTE FUNCTION
        sensor_points_handle();
