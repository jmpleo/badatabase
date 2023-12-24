ALTER TABLE sensorslines ENABLE ROW LEVEL SECURITY;
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY sensorslines_labler_sensor_1_view ON sensorslines FOR
    SELECT TO sensorslines_labler_sensor_1 USING (sensorid = 1);

CREATE POLICY zones_labler_sensor_1_view ON zones FOR
    SELECT TO zones_labler_sensor_1 USING (sensorid = 1);

CREATE POLICY admin_view_sensorslines ON sensorslines FOR
    ALL TO admin USING (TRUE);

CREATE POLICY admin_view_zones ON zones FOR
    ALL TO admin USING (TRUE);

CREATE POLICY auditor_sensor_1_view_sensorlines ON sensorslines FOR
    SELECT TO auditor_sensor_1 USING (sensorid = 1);

CREATE POLICY auditor_sensor_1_view_zones ON zones FOR
    SELECT TO auditor_sensor_1 USING (sensorid = 1);
