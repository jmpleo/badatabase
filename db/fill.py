import os
import argparse
import random
import psycopg2

from datetime import datetime, timedelta
from faker import Faker


def random_sensor(fake):
    p_sensorname = fake.name()
    p_flagsensoron = fake.boolean()
    p_flagusingswith = fake.boolean()
    p_extracmdscript = fake.name()
    p_switchsensorname = fake.name()
    p_average = fake.random_int(min=1, max=100)
    p_freqstart = fake.random_int(min=1, max=1000)
    p_freqstep = fake.random_int(min=1, max=10) / 10
    p_freqstop = fake.random_int(min=int(p_freqstart), max=2000)
    p_sensorlength = fake.random_int(min=1, max=100)
    p_sensorstartpoint = fake.random_int(min=1, max=100)
    p_sensorendpoint = fake.random_int(min=p_sensorstartpoint, max=100)
    p_sensorpointlength = fake.random_int(min=1, max=100)
    p_cwatt = fake.random_int(min=1, max=100)
    p_adpgain = fake.random_int(min=1, max=100)
    p_pulsegain = fake.random_int(min=1, max=100)
    p_pulselength = fake.random_int(min=1, max=100)
    return (
        p_sensorname,
        p_flagsensoron,
        p_flagusingswith,
        p_extracmdscript,
        p_switchsensorname,
        p_average,
        p_freqstart,
        p_freqstep,
        p_freqstop,
        p_sensorlength,
        p_cwatt,
        p_adpgain,
        p_pulsegain,
        p_pulselength,
        p_sensorstartpoint,
        p_sensorendpoint,
        #p_sensorpointlength
    )


def random_badevice(fake):
    p_deviceid = fake.random_int(min=1000, max=1000000)
    p_devicename = fake.word()
    p_adcfreq = fake.random_int(min=10, max=10000)
    p_startdiscret = fake.random_int(min=1, max=10)
    return (
        str(p_deviceid),
        p_devicename,
        p_adcfreq,
        p_startdiscret
    )


def random_line(fake, p_sensorid):
    p_linename = fake.word()
    p_linetype = fake.random_int(min=1, max=100000)
    p_startpoint = fake.random_int(min=1, max=100000)
    p_endpoint = fake.random_int(min=1, max=100000)
    p_direct = fake.random_int(min=1, max=100000)
    p_lengthpoints = fake.random_int(min=1, max=100000)
    p_lengthmeters = fake.pyfloat(5, 5)
    p_mhztemp20 = fake.pyfloat(5, 5)
    p_tempcoeff = fake.pyfloat(5, 5)
    p_defcoeff = fake.pyfloat(5, 5)
    p_auxlineid = fake.random_int(min=1, max=10000)
    return (
        p_sensorid,
        p_linename,
        p_linetype,
        p_startpoint,
        p_endpoint,
        p_direct,
        p_lengthpoints,
        p_lengthmeters,
        p_mhztemp20,
        p_tempcoeff,
        p_defcoeff,
        p_auxlineid,
    )


def random_zone(fake, p_lineid, p_sensorid, p_deviceid):
    p_zonename = fake.word()
    p_zonefullname = fake.word()
    p_zonetype = fake.random_int(min=10, max=100000)
    p_direct = fake.random_int(min=10, max=100000)
    p_startinareax = fake.pyfloat(5, 5)
    p_startinareay = fake.pyfloat(5, 5)
    p_endinareax = fake.pyfloat(5, 5)
    p_endinareay = fake.pyfloat(5, 5)
    p_lengthzoneinarea = fake.pyfloat(5, 5)
    p_startinline = fake.pyfloat(5, 5)
    p_endinline = fake.pyfloat(5, 5)
    p_lengthinline = fake.pyfloat(5, 5)
    return (
        p_lineid,
        p_sensorid,
        p_deviceid,
        p_zonename,
        p_zonetype,
        p_direct,
        p_startinareax,
        p_startinareay,
        p_endinareax,
        p_endinareay,
        p_lengthzoneinarea,
        p_startinline,
        p_endinline,
        p_lengthinline
    )


def random_sweep(fake, p_sensorid, p_sensorname):
    start_date = datetime(2023, 1, 1)
    end_date = datetime(2023, 12, 31)
    time_delta = end_date - start_date
    random_days = random.randint(0, time_delta.days)
    random_date = start_date + timedelta(days=random_days)

    p_sweeptime = random_date.strftime('%Y-%m-%d %H:%M:%S')
    p_average = fake.random_int(min=10, max=100)
    p_freqstart = float(fake.random_int(min=1000, max=2000))
    p_freqstep = float(fake.random_int(min=10, max=100))
    p_freqstop = float(fake.random_int(min=1000, max=2000))
    p_sensorlength = fake.random_int(min=1, max=10000)
    p_sensorpointlength = 10000
    p_sensorstartpoint = fake.random_int(min=1, max=100)
    p_sensorendpoint = p_sensorstartpoint + p_sensorpointlength
    p_cwatt = fake.random_int(min=1, max=10000)
    p_adpgain = fake.random_int(min=-100, max=100)
    p_pulsegain = fake.random_int(min=-100, max=100)
    p_pulselength = fake.random_int(min=-100, max=100)
    p_datalorenz = [
        float(random.randint(-1000, 1000))
        for i in range(p_sensorpointlength)
    ]
    p_shc = float(random.randint(-100, 100))
    p_datalorenz_w = [
        float(random.randint(-1000, 1000))
        for i in range(p_sensorpointlength)
    ]
    p_datalorenz_y0 = [
        float(random.randint(-1000, 1000))
        for i in range(p_sensorpointlength)
    ]
    p_datalorenz_a = [
        float(random.randint(-1000, 1000))
        for i in range(p_sensorpointlength)
    ]
    p_datalorenz_err = [
        float(random.randint(-1000, 1000))
        for i in range(p_sensorpointlength)
    ]
    return (
        p_sweeptime,
        p_sensorid,
        p_sensorname,
        p_average,
        p_freqstart,
        p_freqstep,
        p_freqstop,
        p_sensorlength,
        p_sensorpointlength,
        p_sensorstartpoint,
        p_sensorendpoint,
        p_cwatt,
        p_adpgain,
        p_pulsegain,
        p_pulselength,
        p_datalorenz,
        p_shc,
        p_datalorenz_w,
        p_datalorenz_y0,
        p_datalorenz_a,
        p_datalorenz_err
    )



if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('-H', '--host', type=str, help='', default=os.getenv("DATABASE_HOST"))
    parser.add_argument('-P', '--port', type=str, help='', default=os.getenv("DATABASE_PORT"))
    parser.add_argument('-D', '--dbname', type=str, help='', default=os.getenv("DATABASE_NAME"))
    parser.add_argument('-U', '--user', type=str, help='', default=os.getenv("DATABASE_USER"))
    parser.add_argument('-W', '--password', type=str, help='', default=os.getenv("DATABASE_PASSWORD"))
    parser.add_argument('--devices', type=int, help='', default=0)
    parser.add_argument('--sensors', type=int, help='', default=0)
    parser.add_argument('--sweeps', type=int, help='', default=0)

    args = parser.parse_args()

    faker = Faker()

    conn = psycopg2.connect(
        host=args.host,
        port=args.port,
        database=args.dbname,
        user=args.user,
        password=args.password
    )

    try:
        cur = conn.cursor()

        for i in range(args.devices):
            cur.callproc(f"insert_badeviceinfo_with_update", random_badevice(faker))
            print(f"device {i+1}/{args.devices}", end='\r')
        print("\033[Kdevices ... done")

        for i in range(args.sensors):
            cur.callproc("insert_sensors_without_update", random_sensor(faker))
            print(f"sensor {i+1}/{args.sensors}", end='\r')
        print("\033[Ksensors ... done")

        #print("\nlines...")
        #for _ in range(100):
        #    for sensorid in range(10):
        #        cur.callproc("insert_sensorslines_without_update", random_line(faker, sensorid))
        #        print(f"{i}/1000", end='\r')
        #print()

        #print("\nzones...")
        #for i in range(1000):
        #    cur.execute(
        #        f"select l.lineid, s.sensorid, (select deviceid from badeviceinfo limit 1)"
        #        " from sensorslines l"
        #        " join sensors s on s.sensorid = l.sensorid"
        #        " order by random() limit 1"
        #    )
        #    lid, sid, did = cur.fetchone()
        #    cur.callproc("insert_zones_without_update", random_zone(faker, lid, sid, did))
        #    print(f"{i}/1000", end='\r')

        #cur.execute("select count(*) from sensors");
        #row = cur.fetchone()
        for i in range(args.sweeps):
            cur.execute("select sensorid, sensorname from sensors order by random() limit 1");
            sid, sname = cur.fetchone()
            cur.callproc("insert_sweepdatalorenz_without_update", random_sweep(faker, sid, sname))
            print(f"sweep {i+1}/{args.sweeps}", end='\r')
        print("\033[Ksweeps ... done")

        conn.commit()

    except psycopg2.Error as e:
        print(e.diag.message_primary)


    cur.close()
    conn.close()
