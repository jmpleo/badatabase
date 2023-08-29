/*
 *  Фунция осуществляет мягкую вставку устройства
 *  Если устройство с первичным ключом существует,
 *  то вставляемое устройство игнорируется
 */
--DROP FUNCTION IF EXISTS insert_badeviceinfo_without_update (VARCHAR(16), VARCHAR(32), INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION insert_badeviceinfo_without_update (
    p_deviceid VARCHAR(16),
    p_devicename VARCHAR(32),
    p_adcfreq INTEGER,
    p_startdiscret INTEGER
)
RETURNS VARCHAR(16) AS $$
DECLARE
  r_deviceid VARCHAR(16);
BEGIN
  INSERT INTO badeviceinfo (
    deviceid,
    devicename,
    adcfreq,
    startdiscret
  ) VALUES (
    p_deviceid,
    p_devicename,
    p_adcfreq,
    p_startdiscret
  )
  ON CONFLICT
    DO NOTHING
  RETURNING
    deviceid INTO r_deviceid;
  RETURN r_deviceid;
END;
$$ LANGUAGE plpgsql;


--DROP FUNCTION IF EXISTS insert_badeviceinfo_without_update ( badeviceinfo );
CREATE OR REPLACE FUNCTION insert_badeviceinfo_without_update ( d badeviceinfo )
RETURNS VARCHAR(16) AS $$
DECLARE
  r_deviceid VARCHAR(16);
BEGIN
  INSERT INTO badeviceinfo (
    deviceid,
    devicename,
    adcfreq,
    startdiscret
  ) VALUES (
    d.deviceid,
    d.devicename,
    d.adcfreq,
    d.startdiscret
  )
  ON CONFLICT
    DO NOTHING
  RETURNING
    deviceid INTO r_deviceid;
  RETURN r_deviceid;
END;
$$ LANGUAGE plpgsql;



/*
 * Функция осуществляет жесткую вставку устройства,
 * затирая уже существующую информацю об устройстве
 */
--DROP FUNCTION IF EXISTS insert_badeviceinfo_with_update (VARCHAR(16), VARCHAR(32), INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION insert_badeviceinfo_with_update (
    p_deviceid VARCHAR(16),
    p_devicename VARCHAR(32),
    p_adcfreq INTEGER,
    p_startdiscret INTEGER
)
RETURNS VARCHAR(16) AS $$
DECLARE
  r_deviceid VARCHAR(16);
BEGIN
  DELETE FROM badeviceinfo WHERE deviceid = p_deviceid;
  INSERT INTO badeviceinfo (
    deviceid,
    devicename,
    adcfreq,
    startdiscret
  ) VALUES (
    p_deviceid,
    p_devicename,
    p_adcfreq,
    p_startdiscret
  )
  ON CONFLICT (devicename)
    DO UPDATE
      SET
        deviceid = p_deviceid,
        devicename = p_devicename,
        adcfreq = p_adcfreq,
        startdiscret = p_startdiscret
  RETURNING
    deviceid INTO r_deviceid;
  RETURN r_deviceid;
END;
$$ LANGUAGE plpgsql;


--DROP FUNCTION IF EXISTS insert_badeviceinfo_with_update ( badeviceinfo );
CREATE OR REPLACE FUNCTION insert_badeviceinfo_with_update ( d badeviceinfo )
RETURNS VARCHAR(16) AS $$
DECLARE
  r_deviceid VARCHAR(16);
BEGIN
  DELETE FROM badeviceinfo WHERE deviceid = d.deviceid;
  INSERT INTO badeviceinfo (
    deviceid,
    devicename,
    adcfreq,
    startdiscret
  ) VALUES (
    d.deviceid,
    d.devicename,
    d.adcfreq,
    d.startdiscret
  )
  ON CONFLICT (devicename)
    DO UPDATE
      SET
        deviceid = d.deviceid,
        devicename = d.devicename,
        adcfreq = d.adcfreq,
        startdiscret = d.startdiscret
  RETURNING
    deviceid INTO r_deviceid;
  RETURN r_deviceid;
END;
$$ LANGUAGE plpgsql;


