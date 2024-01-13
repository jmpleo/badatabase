

CREATE ROLE admin WITH LOGIN PASSWORD 'admin';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

CREATE ROLE zones_labeler WITH LOGIN PASSWORD 'zones_labeler';
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO zones_labeler;
GRANT ALL PRIVILEGES ON zones TO zones_labeler;
GRANT ALL PRIVILEGES ON labelers TO zones_labeler;
GRANT SELECT ON select_labelersecret TO zones_labeler;
GRANT ALL PRIVILEGES ON labelerskeys TO zones_labeler;

CREATE ROLE sensorslines_labeler WITH LOGIN PASSWORD 'sensorslines_labeler';
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO sensorslines_labeler;
GRANT ALL PRIVILEGES ON sensorslines TO sensorslines_labeler;
GRANT ALL PRIVILEGES ON labelers TO sensorslines_labeler;
GRANT SELECT ON select_labelersecret TO sensorslines_labeler;
GRANT ALL PRIVILEGES ON labelerskeys TO sensorslines_labeler;

CREATE ROLE auditor WITH LOGIN PASSWORD 'auditor';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor;


