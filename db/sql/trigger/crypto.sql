

CREATE TRIGGER notes_encryption_trigger
BEFORE
    INSERT OR UPDATE ON labelers_notes
FOR
    EACH ROW
EXECUTE
    FUNCTION notes_encryption_handle();


