CREATE USER zones_labeler_sensor_1 WITH PASSWORD 'zones_labeler_sensor_1';
GRANT zones_labeler to zones_labeler_sensor_1;

CREATE USER sensorslines_labeler_sensor_1 WITH PASSWORD 'sensorslines_labeler_sensor_1';
GRANT sensorslines_labeler to sensorslines_labeler_sensor_1;

CREATE USER auditor_sensor_1 WITH PASSWORD 'auditor_sensor_1';
GRANT auditor to auditor_sensor_1;

CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator';

