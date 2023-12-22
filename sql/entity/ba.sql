CREATE TABLE IF NOT EXISTS badeviceinfo (
    deviceid VARCHAR(16) PRIMARY KEY,
    devicename VARCHAR(32) NOT NULL UNIQUE,
    adcfreq INTEGER NOT NULL,
    startdiscret INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sensors (
    sensorid SERIAL PRIMARY KEY,
    sensorname VARCHAR(32) NOT NULL UNIQUE,
    sensorfname VARCHAR(128) NOT NULL DEFAULT '',
    flagsensoron BOOLEAN NOT NULL,
    flagusingswith BOOLEAN NOT NULL,
    extracmdscript VARCHAR(128) NOT NULL,
    switchsensorname VARCHAR(64) NOT NULL,
    comment VARCHAR(256) NOT NULL DEFAULT '',
    average INTEGER NOT NULL,
    freqstart DOUBLE PRECISION NOT NULL,
    freqstep DOUBLE PRECISION NOT NULL,
    freqstop DOUBLE PRECISION NOT NULL,
    sensorlength INTEGER NOT NULL,
    sensorpointlength INTEGER NOT NULL,
    sensorstartpoint INTEGER NOT NULL,
    sensorendpoint INTEGER NOT NULL,
    cwatt INTEGER NOT NULL,
    adpgain INTEGER NOT NULL,
    pulsegain INTEGER NOT NULL,
    pulselength INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sensorslines (
    lineid SERIAL PRIMARY KEY,
    sensorid INTEGER NOT NULL, -- REFERENCES sensors(sensorid),
    linename VARCHAR(32) NOT NULL,
    linefullname VARCHAR(128) NOT NULL DEFAULT '',
    linetype INTEGER NOT NULL,
    startpoint INTEGER NOT NULL,
    endpoint INTEGER NOT NULL,
    direct INTEGER NOT NULL,
    lengthpoints INTEGER NOT NULL,
    lengthmeters DOUBLE PRECISION NOT NULL,
    mhztemp20 DOUBLE PRECISION NOT NULL,
    tempcoeff DOUBLE PRECISION NOT NULL,
    defcoeff DOUBLE PRECISION NOT NULL,
    auxlineid INTEGER NOT NULL,

    CONSTRAINT linename_unique UNIQUE(sensorid, linename)
);

CREATE TABLE IF NOT EXISTS sweepdatalorenz (
    sweepid SERIAL PRIMARY KEY,
    sweeptime TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    sensorid INTEGER NOT NULL, -- REFERENCES sensors(sensorid),
    sensorname VARCHAR(32) NOT NULL, -- REFERENCES sensors(sensorname),
    average INTEGER NOT NULL,
    freqstart DOUBLE PRECISION NOT NULL,
    freqstep DOUBLE PRECISION NOT NULL,
    freqstop DOUBLE PRECISION NOT NULL,
    sensorlength INTEGER NOT NULL,
    sensorpointlength INTEGER NOT NULL,
    sensorstartpoint INTEGER NOT NULL,
    sensorendpoint INTEGER NOT NULL,
    cwatt INTEGER NOT NULL,
    adpgain INTEGER NOT NULL,
    pulsegain INTEGER NOT NULL,
    pulselength INTEGER NOT NULL,
    datalorenz REAL[] NOT NULL,
    shc REAL NOT NULL,
    datalorenz_w REAL[] NOT NULL,
    datalorenz_y0 REAL[] NOT NULL,
    datalorenz_a REAL[] NOT NULL,
    datalorenz_err REAL[] NOT NULL
);

CREATE TABLE IF NOT EXISTS zones (
    zoneid SERIAL PRIMARY KEY,
    extzoneid INTEGER NOT NULL DEFAULT 0,
    lineid INTEGER NOT NULL, -- REFERENCES sensorslines(lineid),
    sensorid INTEGER NOT NULL, -- REFERENCES sensors(sensorid),
    deviceid VARCHAR(16) NOT NULL, -- REFERENCES badeviceinfo(deviceid),
    zonename VARCHAR(32) NOT NULL,
    zonefullname VARCHAR(128) NOT NULL DEFAULT '',
    zonetype INTEGER NOT NULL,
    direct INTEGER NOT NULL,
    startinareax DOUBLE PRECISION NOT NULL,
    startinareay DOUBLE PRECISION NOT NULL,
    endinareax DOUBLE PRECISION NOT NULL,
    endinareay DOUBLE PRECISION NOT NULL,
    lengthzoneinarea DOUBLE PRECISION NOT NULL,
    startinline DOUBLE PRECISION NOT NULL,
    endinline DOUBLE PRECISION NOT NULL,
    lengthinline DOUBLE PRECISION NOT NULL,

    CONSTRAINT zonename_unique UNIQUE(lineid, zonename)
);

