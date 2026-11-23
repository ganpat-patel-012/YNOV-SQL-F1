-- Formula 1 World Championship (1950–2024) PostgreSQL Schema
-- Source: rohanrao/formula-1-world-championship-1950-2020 (Ergast F1 Dataset)

DROP TABLE IF EXISTS lap_times CASCADE;
DROP TABLE IF EXISTS pit_stops CASCADE;
DROP TABLE IF EXISTS sprint_results CASCADE;
DROP TABLE IF EXISTS results CASCADE;
DROP TABLE IF EXISTS qualifying CASCADE;
DROP TABLE IF EXISTS driver_standings CASCADE;
DROP TABLE IF EXISTS constructor_standings CASCADE;
DROP TABLE IF EXISTS constructor_results CASCADE;
DROP TABLE IF EXISTS races CASCADE;
DROP TABLE IF EXISTS status CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;
DROP TABLE IF EXISTS constructors CASCADE;
DROP TABLE IF EXISTS circuits CASCADE;
DROP TABLE IF EXISTS seasons CASCADE;

CREATE TABLE seasons (
    year INTEGER PRIMARY KEY,
    url TEXT NOT NULL
);

CREATE TABLE circuits (
    circuit_id INTEGER PRIMARY KEY,
    circuit_ref TEXT NOT NULL,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    country TEXT NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    alt INTEGER,
    url TEXT NOT NULL
);

CREATE TABLE constructors (
    constructor_id INTEGER PRIMARY KEY,
    constructor_ref TEXT NOT NULL,
    name TEXT NOT NULL,
    nationality TEXT NOT NULL,
    url TEXT NOT NULL
);

CREATE TABLE drivers (
    driver_id INTEGER PRIMARY KEY,
    driver_ref TEXT NOT NULL,
    number INTEGER,
    code TEXT,
    forename TEXT NOT NULL,
    surname TEXT NOT NULL,
    dob DATE NOT NULL,
    nationality TEXT NOT NULL,
    url TEXT NOT NULL
);

CREATE TABLE status (
    status_id INTEGER PRIMARY KEY,
    status TEXT NOT NULL
);

CREATE TABLE races (
    race_id INTEGER PRIMARY KEY,
    year INTEGER NOT NULL REFERENCES seasons(year),
    round INTEGER NOT NULL,
    circuit_id INTEGER NOT NULL REFERENCES circuits(circuit_id),
    name TEXT NOT NULL,
    date DATE NOT NULL,
    time TIME,
    url TEXT NOT NULL,
    fp1_date DATE,
    fp1_time TIME,
    fp2_date DATE,
    fp2_time TIME,
    fp3_date DATE,
    fp3_time TIME,
    quali_date DATE,
    quali_time TIME,
    sprint_date DATE,
    sprint_time TIME
);

CREATE TABLE constructor_results (
    constructor_results_id INTEGER PRIMARY KEY,
    race_id INTEGER NOT NULL REFERENCES races(race_id),
    constructor_id INTEGER NOT NULL REFERENCES constructors(constructor_id),
    points DOUBLE PRECISION NOT NULL,
    status TEXT
);

CREATE TABLE constructor_standings (
    constructor_standings_id INTEGER PRIMARY KEY,
    race_id INTEGER NOT NULL REFERENCES races(race_id),
    constructor_id INTEGER NOT NULL REFERENCES constructors(constructor_id),
    points DOUBLE PRECISION NOT NULL,
    position INTEGER NOT NULL,
    position_text TEXT NOT NULL,
    wins INTEGER NOT NULL
);

CREATE TABLE driver_standings (
    driver_standings_id INTEGER PRIMARY KEY,
    race_id INTEGER NOT NULL REFERENCES races(race_id),
    driver_id INTEGER NOT NULL REFERENCES drivers(driver_id),
    points DOUBLE PRECISION NOT NULL,
    position INTEGER NOT NULL,
    position_text TEXT NOT NULL,
    wins INTEGER NOT NULL
);

CREATE TABLE qualifying (
    qualify_id INTEGER PRIMARY KEY,
    race_id INTEGER NOT NULL REFERENCES races(race_id),
    driver_id INTEGER NOT NULL REFERENCES drivers(driver_id),
    constructor_id INTEGER NOT NULL REFERENCES constructors(constructor_id),
    number INTEGER NOT NULL,
    position INTEGER NOT NULL,
    q1 TEXT,
    q2 TEXT,
    q3 TEXT
);

CREATE TABLE results (
    result_id INTEGER PRIMARY KEY,
    race_id INTEGER NOT NULL REFERENCES races(race_id),
    driver_id INTEGER NOT NULL REFERENCES drivers(driver_id),
    constructor_id INTEGER NOT NULL REFERENCES constructors(constructor_id),
    number INTEGER,
    grid INTEGER NOT NULL,
    position INTEGER,
    position_text TEXT NOT NULL,
    position_order INTEGER NOT NULL,
    points DOUBLE PRECISION NOT NULL,
    laps INTEGER NOT NULL,
    time TEXT,
    milliseconds INTEGER,
    fastest_lap INTEGER,
    rank INTEGER,
    fastest_lap_time TEXT,
    fastest_lap_speed DOUBLE PRECISION,
    status_id INTEGER NOT NULL REFERENCES status(status_id)
);

CREATE TABLE sprint_results (
    result_id INTEGER PRIMARY KEY,
    race_id INTEGER NOT NULL REFERENCES races(race_id),
    driver_id INTEGER NOT NULL REFERENCES drivers(driver_id),
    constructor_id INTEGER NOT NULL REFERENCES constructors(constructor_id),
    number INTEGER NOT NULL,
    grid INTEGER NOT NULL,
    position INTEGER,
    position_text TEXT NOT NULL,
    position_order INTEGER NOT NULL,
    points DOUBLE PRECISION NOT NULL,
    laps INTEGER NOT NULL,
    time TEXT,
    milliseconds INTEGER,
    fastest_lap INTEGER,
    fastest_lap_time TEXT,
    status_id INTEGER NOT NULL REFERENCES status(status_id)
);

CREATE TABLE pit_stops (
    race_id INTEGER NOT NULL REFERENCES races(race_id),
    driver_id INTEGER NOT NULL REFERENCES drivers(driver_id),
    stop INTEGER NOT NULL,
    lap INTEGER NOT NULL,
    time TIME NOT NULL,
    duration TEXT NOT NULL,
    milliseconds INTEGER NOT NULL,
    PRIMARY KEY (race_id, driver_id, stop)
);

CREATE TABLE lap_times (
    race_id INTEGER NOT NULL REFERENCES races(race_id),
    driver_id INTEGER NOT NULL REFERENCES drivers(driver_id),
    lap INTEGER NOT NULL,
    position INTEGER NOT NULL,
    time TEXT NOT NULL,
    milliseconds INTEGER NOT NULL,
    PRIMARY KEY (race_id, driver_id, lap)
);

-- Helpful indexes for common analytical queries
CREATE INDEX idx_races_year ON races(year);
CREATE INDEX idx_races_circuit_id ON races(circuit_id);
CREATE INDEX idx_results_race_id ON results(race_id);
CREATE INDEX idx_results_driver_id ON results(driver_id);
CREATE INDEX idx_results_constructor_id ON results(constructor_id);
CREATE INDEX idx_qualifying_race_id ON qualifying(race_id);
CREATE INDEX idx_qualifying_driver_id ON qualifying(driver_id);
CREATE INDEX idx_driver_standings_race_id ON driver_standings(race_id);
CREATE INDEX idx_driver_standings_driver_id ON driver_standings(driver_id);
CREATE INDEX idx_constructor_standings_race_id ON constructor_standings(race_id);
CREATE INDEX idx_constructor_results_race_id ON constructor_results(race_id);
CREATE INDEX idx_lap_times_driver_id ON lap_times(driver_id);
CREATE INDEX idx_pit_stops_driver_id ON pit_stops(driver_id);
