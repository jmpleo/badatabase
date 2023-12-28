ALTER TABLE sensorslines ENABLE ROW LEVEL SECURITY;
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE labelers_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY sensorslines_labeler_sensor_1_view ON sensorslines FOR
    SELECT TO sensorslines_labeler_sensor_1 USING (sensorid = 1);

CREATE POLICY zones_labeler_sensor_1_view ON zones FOR
    SELECT TO zones_labeler_sensor_1 USING (sensorid = 1);

CREATE POLICY admin_view_sensorslines ON sensorslines FOR
    ALL TO admin USING (TRUE);

CREATE POLICY admin_view_zones ON zones FOR
    ALL TO admin USING (TRUE);

CREATE POLICY auditor_sensor_1_view_sensorlines ON sensorslines FOR
    SELECT TO auditor_sensor_1 USING (sensorid = 1);

CREATE POLICY auditor_sensor_1_view_zones ON zones FOR
    SELECT TO auditor_sensor_1 USING (sensorid = 1);

CREATE POLICY sensorslines_labeler_view_only_self_key ON labelers_keys FOR
    SELECT TO sensorslines_labeler USING (labelername = CURRENT_USER);

CREATE POLICY zones_labeler_view_only_self_key ON labelers_keys FOR
    SELECT TO zones_labeler USING (labelername = CURRENT_USER);
