CREATE ROLE admin WITH LOGIN PASSWORD 'admin';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

CREATE ROLE zones_labeler WITH LOGIN PASSWORD 'zones_labeler';
GRANT INSERT ON zones TO zones_labeler;
GRANT SELECT ON TABLE labelers TO zones_labeler;

CREATE ROLE sensorslines_labeler WITH LOGIN PASSWORD 'sensorslines_labeler';
GRANT INSERT ON sensorslines TO sensorslines_labeler;
GRANT SELECT ON TABLE labelers TO sensorslines_labeler;

CREATE ROLE auditor WITH LOGIN PASSWORD 'auditor';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor;

