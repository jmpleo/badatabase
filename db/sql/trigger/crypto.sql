

CREATE TRIGGER insert_labeler_trigger
BEFORE
    INSERT OR UPDATE ON labelers
FOR
    EACH ROW
EXECUTE
    FUNCTION insert_labeler_handle();

