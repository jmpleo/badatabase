CREATE OR REPLACE VIEW select_labelersecret AS
    SELECT
        select_labelersecret(labelersecret, labelername) AS labelersecret
    FROM
        labelers
    WHERE labelername = CURRENT_USER;
