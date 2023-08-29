CREATE OR REPLACE FUNCTION insert_with_update /*_table */(
    -- p_field TYPE
) RETURNS INT AS $$
DECLARE
    r_id INT;
BEGIN
    IF p_id IS NOT NULL THEN
        UPDATE -- table
        SET
            -- field = p_field
        WHERE
            id = p_id
        RETURNING
            id INTO r_id;

        IF FOUND THEN
            RETURN r_id;
        END IF;
    END IF;

    INSERT INTO sensors (
        -- field
    ) VALUES (
        -- p_field
    )
    ON CONFLICT (sensorname)
    DO UPDATE SET
        -- field = p_field
    RETURNING id INTO r_id;
    RETURN r_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_without_update /*_table */(
    -- p_field TYPE
) RETURNS INT AS $$
DECLARE
    r_id INT;
BEGIN
    IF p_id IS NOT NULL THEN
        SELECT id FROM /* table */ WHERE id = p_id INTO r_id;
        IF FOUND THEN
            RETURN r_id;
        END IF;
    END IF;

    INSERT INTO sensors (
        -- field
    ) VALUES (
        -- p_field
    )
    ON CONFLICT (sensorname)
    DO NOTHING
    RETURNING id INTO r_id;
    RETURN r_id;
END;
$$ LANGUAGE plpgsql;


