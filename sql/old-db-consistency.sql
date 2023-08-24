ALTER TABLE zones
ADD COLUMN IF NOT EXISTS extzoneid INTEGER NOT NULL DEFAULT 0;

ALTER TABLE sweepdatalorenz
ADD COLUMN IF NOT EXISTS shc REAL NOT NULL DEFAULT 0;

--DELETE FROM sensors WHERE sensorid NOT IN (
--  SELECT MIN(sensorid) FROM sensors GROUP BY sensorname
--);

ALTER TABLE sensors
DROP CONSTRAINT IF EXISTS sensorname_unique;
ALTER TABLE sensors
ADD CONSTRAINT sensorname_unique UNIQUE(sensorname);

--DELETE FROM sensorslines WHERE lineid NOT IN (
--  SELECT MIN(lineid) FROM sensorslines GROUP BY linename
--);

ALTER TABLE sensorslines
DROP CONSTRAINT IF EXISTS linename_unique;
ALTER TABLE sensorslines
ADD CONSTRAINT linename_unique UNIQUE(sensorid, linename);

--DELETE FROM zones WHERE zoneid NOT IN (
--  SELECT MIN(zoneid) FROM zones GROUP BY zonename
--);

ALTER TABLE zones
DROP CONSTRAINT IF EXISTS zonename_unique;
ALTER TABLE zones
ADD CONSTRAINT zonename_unique UNIQUE(lineid, zonename);
