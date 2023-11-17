CREATE USER admin WITH PASSWORD 'admin';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

CREATE USER labler WITH PASSWORD 'labler';
GRANT SELECT, INSERT, UPDATE ON sensorslines TO labler;
GRANT SELECT, INSERT, UPDATE ON zones TO labler;

CREATE USER viewer WITH PASSWORD 'viewer';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer;