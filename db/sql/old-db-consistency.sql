ALTER TABLE sweepdatalorenz
ADD COLUMN IF NOT EXISTS shc REAL NOT NULL DEFAULT 0;

ALTER TABLE sensors
DROP CONSTRAINT IF EXISTS sensorname_unique;
ALTER TABLE sensors
ADD CONSTRAINT sensorname_unique UNIQUE(sensorname);

ALTER TABLE sensorslines
DROP CONSTRAINT IF EXISTS linename_unique;
ALTER TABLE sensorslines
ADD CONSTRAINT linename_unique UNIQUE(sensorid, linename);

ALTER TABLE zones
DROP CONSTRAINT IF EXISTS zonename_unique;
ALTER TABLE zones
ADD CONSTRAINT zonename_unique UNIQUE(lineid, zonename);
ALTER TABLE zones
ADD COLUMN IF NOT EXISTS extzoneid INTEGER NOT NULL DEFAULT 0;
