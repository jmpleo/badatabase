

CREATE OR REPLACE FUNCTION select_labelersecret(p_secret TEXT, p_labelername TEXT)
RETURNS TEXT AS $$
DECLARE
    decrypt_secret TEXT;
BEGIN
    IF
        CURRENT_USER NOT IN (SELECT labelername FROM labelerskeys)
    THEN
        RAISE EXCEPTION 'User does not have a key';
    END IF;

    IF
        p_labelername != 'admin'
        AND
        p_labelername != CURRENT_USER
    THEN
        RAISE EXCEPTION 'Permission denied to update data';
    END IF;

    decrypt_secret := pgp_sym_decrypt(
        p_secret::BYTEA,
        (SELECT labelerkey FROM labelerskeys WHERE labelername = CURRENT_USER)
    );
    RETURN decrypt_secret;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_labeler_handle()
RETURNS TRIGGER AS $$
BEGIN
    IF
        CURRENT_USER NOT IN (SELECT labelername FROM labelerskeys)
    THEN
        RAISE EXCEPTION 'User have not a key';
    END IF;

    IF
        NEW.labelername != CURRENT_USER
        AND
        NEW.labelername != 'admin'
    THEN
        RAISE EXCEPTION 'Permission denied to update data';
    END IF;

    NEW.labelersecret:= pgp_sym_encrypt(
        NEW.labelersecret,
        (SELECT labelerkey FROM labelerskeys WHERE labelername = CURRENT_USER)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


