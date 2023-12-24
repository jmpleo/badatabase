CREATE ROLE admin WITH LOGIN PASSWORD 'admin';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

CREATE ROLE zones_labler WITH LOGIN PASSWORD 'zones_labler';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO zones_labler;
GRANT INSERT ON zones TO zones_labler;

CREATE ROLE sensorslines_labler WITH LOGIN PASSWORD 'sensorslines_labler';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO sensorslines_labler;
GRANT INSERT ON sensorslines TO sensorslines_labler;

CREATE ROLE auditor WITH LOGIN PASSWORD 'auditor';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor;
