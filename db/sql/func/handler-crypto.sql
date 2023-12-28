

CREATE OR REPLACE FUNCTION notes_encryption_handle()
RETURNS TRIGGER AS $$
BEGIN
    IF
        CURRENT_USER NOT IN (SELECT labelername FROM labelers_keys)
    THEN
        RAISE EXCEPTION 'User have not a key';
    END IF;

    IF
        CURRENT_USER != NEW.labelername
    THEN
        RAISE EXCEPTION 'Permission denied to update data';
    END IF;

    NEW.notes := pgp_sym_encrypt(
        NEW.notes, (
            SELECT
                key
            FROM
                labelers_keys
            WHERE
                labelername = CURRENT_USER
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


