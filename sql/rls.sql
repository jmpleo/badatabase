ALTER TABLE sensorslines ENABLE ROW LEVEL SECURITY;
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY view_sensor_1 ON sensorslines FOR
    SELECT TO sensorslines_labler_sensor_1 USING (sensorid = 1);

CREATE POLICY view_sensor_1 ON zones FOR
    SELECT TO zones_labler_sensor_1 USING (sensorid = 1);

CREATE POLICY view_all ON sensorslines FOR
    ALL TO admin USING (TRUE);

CREATE POLICY view_all ON zones FOR
    ALL TO admin USING (TRUE);

CREATE POLICY view_sensor_1 ON sensorslines FOR
    SELECT TO auditor_sensor_1 USING (sensorid = 1);

CREATE POLICY view_sensor_1 ON zones FOR
    SELECT TO auditor_sensor_1 USING (sensorid = 1);
