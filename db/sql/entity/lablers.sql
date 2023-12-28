

CREATE TABLE labelers (
    labelerid SERIAL PRIMARY KEY,
    labelername VARCHAR(50) NOT NULL UNIQUE,
    timestamp TIMESTAMP DEFAULT now()
);


CREATE TABLE labelers_keys (
    keyid SERIAL PRIMARY KEY,
    key TEXT NOT NULL DEFAULT '',
    labelername VARCHAR(50) NOT NULL REFERENCES labelers(labelername)
);


CREATE TABLE labelers_notes (
    noteid SERIAL PRIMARY KEY,
    note TEXT NOT NULL DEFAULT '',
    labelerid INTEGER REFERENCES labelers(labelerid)
);


