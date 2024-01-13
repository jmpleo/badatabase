

CREATE TABLE labelers (
    labelerid SERIAL PRIMARY KEY,
    labelername VARCHAR(50) NOT NULL UNIQUE DEFAULT CURRENT_USER,
    labelersecret TEXT NOT NULL DEFAULT ''
);


CREATE TABLE labelerskeys (
    keyid SERIAL PRIMARY KEY,
    labelerkey TEXT NOT NULL DEFAULT '',
    labelername VARCHAR(50) NOT NULL UNIQUE DEFAULT CURRENT_USER
);


