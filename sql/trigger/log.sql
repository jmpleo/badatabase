CREATE OR REPLACE FUNCTION zones_audit_log_trigger_handle()
RETURNS TRIGGER AS $$
BEGIN
   IF (TG_OP = 'INSERT') THEN
        INSERT INTO zones_audit_log (
            zone_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            NEW.zoneid,
            null,
            to_jsonb(NEW),
            'INSERT',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN NEW;

   ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO zones_audit_log (
            zone_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            NEW.zoneid,
            to_jsonb(OLD),
            to_jsonb(NEW),
            'UPDATE',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN NEW;

   ELSIF (TG_OP = 'DELETE') THEN
       INSERT INTO zones_audit_log (
            zone_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            OLD.zoneid,
            to_jsonb(OLD),
            null,
            'DELETE',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN OLD;

   END IF;

END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sensorslines_audit_log_trigger_handle()
RETURNS TRIGGER AS $$
BEGIN
   IF (TG_OP = 'INSERT') THEN
        INSERT INTO sensorslines_audit_log (
            line_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            NEW.lineid,
            null,
            to_jsonb(NEW),
            'INSERT',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN NEW;

   ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO sensorslines_audit_log (
            line_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            NEW.lineid,
            to_jsonb(OLD),
            to_jsonb(NEW),
            'UPDATE',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN NEW;

   ELSIF (TG_OP = 'DELETE') THEN
       INSERT INTO sensorslines_audit_log (
            line_id,
            old_row_data,
            new_row_data,
            dml_type,
            dml_timestamp,
            dml_created_by
        )
        VALUES (
            OLD.lineid,
            to_jsonb(OLD),
            null,
            'DELETE',
            CURRENT_TIMESTAMP,
            (SELECT USER)
        );
        RETURN OLD;

   END IF;

END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER sensorslines_audit_log_trigger
    AFTER
        INSERT OR UPDATE OR DELETE
    ON
        sensorslines
    FOR
        EACH ROW
    EXECUTE FUNCTION
        sensorslines_audit_log_trigger_handle();


CREATE OR REPLACE TRIGGER zones_audit_log_trigger
    AFTER
        INSERT OR UPDATE OR DELETE
    ON
        zones
    FOR
        EACH ROW
    EXECUTE FUNCTION
        zones_audit_log_trigger_handle();


