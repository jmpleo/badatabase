

CREATE TABLE IF NOT EXISTS badeviceinfo (
    deviceid VARCHAR(16) PRIMARY KEY,
    devicename VARCHAR(32) NOT NULL UNIQUE,
    adcfreq INTEGER NOT NULL CHECK (adcfreq >= 0),
    startdiscret INTEGER NOT NULL CHECK (startdiscret >= 0)
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
    average INTEGER NOT NULL CHECK (average >= 0),
    freqstart DOUBLE PRECISION NOT NULL CHECK (freqstart >= 0),
    freqstep DOUBLE PRECISION NOT NULL CHECK (freqstep >= 0),
    freqstop DOUBLE PRECISION NOT NULL,
    sensorlength INTEGER NOT NULL,
    sensorstartpoint INTEGER CHECK (sensorstartpoint >= 0),
    sensorendpoint INTEGER CHECK (sensorendpoint >= 0),
    sensorpointlength INTEGER CHECK (sensorpointlength >= 0),
    cwatt INTEGER NOT NULL,
    adpgain INTEGER NOT NULL,
    pulsegain INTEGER NOT NULL,
    pulselength INTEGER NOT NULL
);


CREATE TABLE IF NOT EXISTS sensorslines (
    lineid SERIAL PRIMARY KEY,
    sensorid INTEGER NOT NULL REFERENCES sensors(sensorid),
    linename VARCHAR(32) NOT NULL,
    linefullname VARCHAR(128) NOT NULL DEFAULT '',
    linetype INTEGER NOT NULL,
    startpoint INTEGER NOT NULL CHECK (startpoint >= 0),
    endpoint INTEGER NOT NULL CHECK (endpoint >= 0),
    direct INTEGER NOT NULL,
    lengthpoints INTEGER NOT NULL CHECK (lengthpoints >= 0),
    lengthmeters DOUBLE PRECISION NOT NULL CHECK (lengthmeters >= 0),
    mhztemp20 DOUBLE PRECISION NOT NULL,
    tempcoeff DOUBLE PRECISION NOT NULL,
    defcoeff DOUBLE PRECISION NOT NULL,
    auxlineid INTEGER NOT NULL,

    CONSTRAINT linename_unique UNIQUE (sensorid, linename)
);


CREATE TABLE IF NOT EXISTS sweepdatalorenz (
    sweepid SERIAL PRIMARY KEY,
    sweeptime TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    sensorid INTEGER NOT NULL REFERENCES sensors(sensorid),
    sensorname VARCHAR(32) NOT NULL REFERENCES sensors(sensorname),
    average INTEGER NOT NULL,
    freqstart DOUBLE PRECISION NOT NULL CHECK (freqstart >= 0),
    freqstep DOUBLE PRECISION NOT NULL CHECK (freqstep >= 0),
    freqstop DOUBLE PRECISION NOT NULL,
    sensorlength INTEGER NOT NULL CHECK (sensorlength >= 0),
    sensorpointlength INTEGER NOT NULL CHECK (sensorpointlength >= 0),
    sensorstartpoint INTEGER NOT NULL CHECK (sensorstartpoint >= 0),
    sensorendpoint INTEGER NOT NULL CHECK (sensorendpoint >= 0),
    cwatt INTEGER NOT NULL,
    adpgain INTEGER NOT NULL,
    pulsegain INTEGER NOT NULL,
    pulselength INTEGER NOT NULL, datalorenz REAL[] NOT NULL,
    shc REAL NOT NULL,
    datalorenz_w REAL[] NOT NULL,
    datalorenz_y0 REAL[] NOT NULL,
    datalorenz_a REAL[] NOT NULL,
    datalorenz_err REAL[] NOT NULL,

    CONSTRAINT sweepdatalorenz_unique UNIQUE(sensorid, sweeptime),
    CONSTRAINT array_length CHECK (
        array_length(datalorenz, 1) = array_length(datalorenz_w, 1)
        AND array_length(datalorenz, 1) = array_length(datalorenz_y0, 1)
        AND array_length(datalorenz, 1) = array_length(datalorenz_a, 1)
        AND array_length(datalorenz, 1) = array_length(datalorenz_err, 1)
    )
);


CREATE TABLE IF NOT EXISTS zones (
    zoneid SERIAL PRIMARY KEY,
    extzoneid INTEGER NOT NULL DEFAULT 0,
    lineid INTEGER NOT NULL REFERENCES sensorslines(lineid),
    sensorid INTEGER NOT NULL REFERENCES sensors(sensorid),
    deviceid VARCHAR(16) NOT NULL REFERENCES badeviceinfo(deviceid),
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


