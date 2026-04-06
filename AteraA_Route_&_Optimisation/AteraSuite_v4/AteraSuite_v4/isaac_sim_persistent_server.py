"""
Atera Analytics - Isaac Sim PERSISTENT Server
Innovate UK Project 10153306 - CAM Pathfinder One

Starts ONCE. Stays running. Accepts jobs from Flask via a shared job queue file.
Flask never spawns a new Isaac Sim process per request - it just writes a job
and reads progress. R Shiny polls Flask for live updates.

Run ONCE with:
    C:/isaac-sim/python.bat isaac_sim_persistent_server.py

Then start Flask (standard Python):
    python isaac_sim_flask_api_DUAL_VEHICLE.py

Isaac Sim will be ready immediately for all subsequent R Shiny requests.
"""

from omni.isaac.kit import SimulationApp

simulation_app = SimulationApp({
    "headless":      True,
    "width":         1,
    "height":        1,
    "renderer":      "RayTracedLighting",
    "active_gpu":    0,
    "multi_gpu":     False,
    "physics_gpu":   0,
    "anti_aliasing": 0
})

from omni.isaac.core import World
from omni.isaac.core.objects import DynamicCuboid
import numpy as np
import requests
import json
import math
import random
import time
import os
import sys
import traceback
from datetime import datetime

# ============================================================================
# JOB QUEUE PATHS — Flask and Isaac Sim share these files
# Stored next to this script so both processes can find them
# ============================================================================

BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
QUEUE_DIR  = os.path.join(BASE_DIR, "shared", "queue")
os.makedirs(QUEUE_DIR, exist_ok=True)

JOBS_DIR     = os.path.join(QUEUE_DIR, "jobs")       # Flask writes job JSON here
PROGRESS_DIR = os.path.join(QUEUE_DIR, "progress")   # Isaac Sim writes progress here
RESULTS_DIR  = os.path.join(QUEUE_DIR, "results")    # Isaac Sim writes final JSON here

for d in [JOBS_DIR, PROGRESS_DIR, RESULTS_DIR]:
    os.makedirs(d, exist_ok=True)

def job_path(job_id):     return os.path.join(JOBS_DIR,     f"{job_id}.json")
def progress_path(job_id):return os.path.join(PROGRESS_DIR, f"{job_id}.json")
def result_path(job_id):  return os.path.join(RESULTS_DIR,  f"{job_id}.json")

def write_progress(job_id, status, pct, message, log_lines=None):
    """Write progress update - Flask reads this on each poll."""
    data = {
        "job_id":    job_id,
        "status":    status,     # "running" | "complete" | "error"
        "percent":   pct,
        "message":   message,
        "timestamp": datetime.now().isoformat(),
        "log":       log_lines or []
    }
    path = progress_path(job_id)
    with open(path + ".tmp", "w") as f:
        json.dump(data, f)
    os.replace(path + ".tmp", path)   # atomic write

def log(job_id, msg, log_store):
    ts = datetime.now().strftime("%H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    log_store.append(line)
    return log_store

# ============================================================================
# VEHICLE CONFIGURATIONS
# ============================================================================

VEHICLES = {
    "kia_niro_ev": {
        "name":             "Kia Niro EV (2023-2025)",
        "mass_kg":          1739,
        "power_kw":         150,
        "battery_kwh":      64.8,
        "max_speed_kmh":    167,
        "length_m":         4.42,
        "width_m":          1.82,
        "height_m":         1.57,
        "wheelbase_m":      2.72,
        "drag_coefficient": 0.29,
        "frontal_area_m2":  2.58,
        "wheel_radius_m":   0.335,
        "cog_height_m":     0.55,
        "spring_k":         28000,
        "damper_c":         2800,
        "tire_mu_dry":      1.05,
        "tire_mu_wet":      0.72,
        "tire_mu_ice":      0.25
    },
    "renault_etech_t": {
        "name":             "Renault E-Tech T 42-tonne HGV",
        "mass_kg":          8500,
        "mass_loaded_kg":   42000,
        "power_kw":         490,
        "battery_kwh":      540,
        "max_speed_kmh":    90,
        "length_m":         11.0,
        "width_m":          2.5,
        "height_m":         3.8,
        "wheelbase_m":      6.0,
        "drag_coefficient": 0.42,
        "frontal_area_m2":  8.5,
        "wheel_radius_m":   0.55,
        "cog_height_m":     1.45,
        "spring_k":         280000,
        "damper_c":         18000,
        "tire_mu_dry":      0.85,
        "tire_mu_wet":      0.60,
        "tire_mu_ice":      0.20
    }
}

# ============================================================================
# SENSORS
# ============================================================================

class CameraSensor:
    def simulate(self, weather, time_of_day, road_quality):
        wd = {"clear":0,"light_rain":-1.5,"heavy_rain":-3.5,"fog":-4.5,"snow":-5.0}
        td = {"day":0,"dusk":-1.2,"night":-2.5}
        s  = road_quality + wd.get(weather,0) + td.get(time_of_day,0) + random.uniform(-0.3,0.3)
        return {
            "lane_visibility":        round(max(0.0,min(10.0,s)), 2),
            "sign_confidence":        round(max(0.0,min(1.0, 0.97+wd.get(weather,0)*0.04+random.uniform(-0.03,0.03))), 3),
            "object_detection_conf":  round(max(0.0,min(1.0, 0.93+wd.get(weather,0)*0.03+random.uniform(-0.02,0.02))), 3)
        }

class LiDARSensor:
    def simulate(self, weather, road_type):
        base   = {"motorway":850,"a_road":750,"urban":640}.get(road_type,750)
        factor = {"clear":1.0,"light_rain":0.86,"heavy_rain":0.64,"fog":0.48,"snow":0.42}.get(weather,1.0)
        density= base*factor+random.uniform(-40,40)
        return {
            "point_density":        round(density,1),
            "detection_confidence": round(max(0.0,min(1.0,min(0.96,density/1000)+random.uniform(-0.04,0.04))),3),
            "effective_range_m":    round(max(20,120*factor+random.uniform(-5,5)),1)
        }

class IMUSensor:
    def simulate(self, accel, angular_vel):
        return {
            "accel_x": round(accel[0]+random.gauss(0,0.01),4),
            "accel_y": round(accel[1]+random.gauss(0,0.01),4),
            "accel_z": round(accel[2]+random.gauss(0,0.01)+9.81,4),
            "gyro_x":  round(angular_vel[0]+random.gauss(0,0.001),5),
            "gyro_y":  round(angular_vel[1]+random.gauss(0,0.001),5),
            "gyro_z":  round(angular_vel[2]+random.gauss(0,0.001),5)
        }

def av_readiness(cam, lidar):
    lv  = cam.get("lane_visibility",5.0)    if cam   else 5.0
    ld  = lidar.get("point_density",500)    if lidar else 500
    cc  = cam.get("sign_confidence",0.5)    if cam   else 0.5
    lc  = lidar.get("detection_confidence",0.5) if lidar else 0.5
    s   = ((lv/10)*0.3+(ld/1000)*0.3+cc*0.2+lc*0.2)*10
    s   = max(0.0,min(10.0,s+random.uniform(-0.1,0.1)))
    st  = "GREEN" if s>=7.5 else "AMBER" if s>=5.0 else "RED"
    return round(s,2), st

# ============================================================================
# PHYSICS VEHICLE (persistent - reused across jobs)
# ============================================================================

class PhysicsVehicle:
    def __init__(self, world_obj, vcfg, mass):
        self.config = vcfg
        self.mass   = mass
        self._prev_vel = np.zeros(3)
        self._dt = 1.0/60.0
        self.prim = DynamicCuboid(
            prim_path="/World/Vehicle",
            name="vehicle_body",
            position=np.array([0.0, 0.0, vcfg["height_m"]/2+0.1]),
            size=1.0,
            scale=np.array([vcfg["width_m"], vcfg["length_m"], vcfg["height_m"]]),
            mass=float(mass)
        )
        world_obj.scene.add(self.prim)
        world_obj.reset()

    def reset_position(self, world_obj):
        """Reset vehicle to origin for new simulation."""
        world_obj.clear()
        # Re-add vehicle
        self.prim = DynamicCuboid(
            prim_path="/World/Vehicle",
            name="vehicle_body",
            position=np.array([0.0, 0.0, self.config["height_m"]/2+0.1]),
            size=1.0,
            scale=np.array([self.config["width_m"], self.config["length_m"], self.config["height_m"]]),
            mass=float(self.mass)
        )
        world_obj.scene.add(self.prim)
        world_obj.reset()
        self._prev_vel = np.zeros(3)

    def get_state(self):
        lv  = np.array(self.prim.get_linear_velocity())
        av  = np.array(self.prim.get_angular_velocity())
        pos,_ = self.prim.get_world_pose()
        pos = np.array(pos)
        spd = float(np.linalg.norm(lv))
        return lv, av, pos, spd, spd*3.6

    def step_to_speed(self, target_kmh, n=15):
        target_ms = target_kmh/3.6
        max_f = min(self.config["power_kw"]*1000/max(target_ms,1.0), self.mass*5.0)
        for _ in range(n):
            lv,_,_,spd,_ = self.get_state()
            diff = target_ms - spd
            self.prim.apply_force(np.array([float(np.clip(diff*self.mass*0.5,-max_f,max_f)),0,0]))
            world.step(render=False)
        return self.get_state()

    def compute_physics(self, lv, av, pos, spd, pcfg, rtype, weather):
        result = {}
        cfg    = self.config
        dt     = self._dt*15

        if pcfg.get("velocity"):
            result.update({"linear_velocity_ms":[round(float(v),4) for v in lv],
                           "speed_ms":round(spd,3),"speed_kmh":round(spd*3.6,2)})
        if pcfg.get("angular_velocity"):
            result.update({"angular_velocity_rads":[round(float(v),5) for v in av],
                           "yaw_rate_degs":round(math.degrees(float(av[2])),3)})
        if pcfg.get("position"):
            result["position_m"] = [round(float(p),3) for p in pos]

        accel = (lv-self._prev_vel)/dt if dt>0 else np.zeros(3)
        if pcfg.get("acceleration"):
            result.update({"acceleration_ms2":[round(float(a),4) for a in accel],
                           "acceleration_g":round(float(np.linalg.norm(accel))/9.81,4),
                           "longitudinal_accel_ms2":round(float(accel[0]),4),
                           "lateral_accel_ms2":round(float(accel[1]),4)})
        if pcfg.get("momentum"):
            mom = lv*self.mass
            result.update({"momentum_kgms":[round(float(m),2) for m in mom],
                           "momentum_magnitude":round(float(np.linalg.norm(mom)),2)})
        if pcfg.get("mass_inertia"):
            w,l,h=cfg["width_m"],cfg["length_m"],cfg["height_m"]
            result.update({"mass_kg":self.mass,
                           "inertia_ixx":round((1/12)*self.mass*(h**2+l**2),1),
                           "inertia_iyy":round((1/12)*self.mass*(w**2+h**2),1),
                           "inertia_izz":round((1/12)*self.mass*(w**2+l**2),1)})
        if pcfg.get("aerodynamics"):
            drag=0.5*1.225*cfg["drag_coefficient"]*cfg["frontal_area_m2"]*spd**2
            result.update({"aerodynamic_drag_N":round(drag,1),
                           "aero_drag_power_kW":round(drag*spd/1000,3),
                           "drag_coefficient":cfg["drag_coefficient"],
                           "frontal_area_m2":cfg["frontal_area_m2"]})
        if pcfg.get("tire_friction"):
            mu = cfg["tire_mu_wet"] if weather in ["light_rain","heavy_rain"] else \
                 cfg["tire_mu_ice"] if weather in ["ice","snow"] else cfg["tire_mu_dry"]
            nfw=(self.mass*9.81)/4
            result.update({"tire_friction_coeff":round(mu,3),
                           "max_friction_force_N":round(mu*nfw,1),
                           "normal_force_per_wheel_N":round(nfw,1)})
        if pcfg.get("suspension"):
            stat=(self.mass*9.81/4)/cfg["spring_k"]
            dyn =float(abs(accel[2]))*self.mass/(4*cfg["spring_k"])
            result.update({"suspension_static_deflection_m":round(stat,4),
                           "suspension_dynamic_delta_m":round(dyn,5),
                           "spring_rate_Nm":cfg["spring_k"],
                           "damper_rate_Nsm":cfg["damper_c"]})
        if pcfg.get("braking"):
            bf=max(0,-float(accel[0]))*self.mass
            result.update({"braking_force_N":round(bf,1),
                           "max_braking_force_N":round(cfg["tire_mu_dry"]*self.mass*9.81,1),
                           "braking_decel_ms2":round(bf/max(self.mass,1),4)})
        if pcfg.get("drivetrain"):
            wr=cfg["wheel_radius_m"]
            rpm=(spd/wr)*60/(2*math.pi)
            tf=cfg["power_kw"]*1000/max(spd,0.1)
            result.update({"wheel_speed_rpm":round(rpm,1),
                           "tractive_force_N":round(min(tf,self.mass*9.81),1),
                           "power_demand_kW":round(cfg["power_kw"]*min(1.0,spd/(cfg["max_speed_kmh"]/3.6)),1)})
        if pcfg.get("steering"):
            yr=float(av[2])
            sa=math.degrees(math.atan2(yr*cfg["wheelbase_m"],max(spd,0.1)))
            result.update({"steering_angle_deg":round(sa,3),"yaw_rate_rads":round(yr,5),
                           "turning_radius_m":round(spd/max(abs(yr),1e-6),2) if abs(yr)>1e-4 else None})
        if pcfg.get("wheels"):
            wr=cfg["wheel_radius_m"]
            result.update({"wheel_speed_rpm":round((spd/wr)*60/(2*math.pi),1),
                           "longitudinal_slip":round(random.uniform(0,0.05),4),
                           "wheel_radius_m":wr})
        if pcfg.get("contact_forces"):
            llt=self.mass*float(abs(accel[1]))*cfg.get("cog_height_m",0.6)/cfg["width_m"]
            result.update({"normal_force_N":round(self.mass*9.81,1),
                           "lateral_load_transfer_N":round(llt,1)})

        self._prev_vel = lv.copy()
        return result

# ============================================================================
# ROUTING
# ============================================================================

class RoadNetwork:
    OSRM = "http://router.project-osrm.org"

    def geocode(self, location):
        try:
            r = requests.get("https://nominatim.openstreetmap.org/search",
                             params={"q":location,"format":"json","limit":1},
                             headers={"User-Agent":"AteraAnalytics/2.0"}, timeout=10)
            if r.status_code==200 and r.json():
                res=r.json()[0]
                return float(res["lat"]),float(res["lon"])
        except Exception as e:
            print(f"  [ERR] Geocode: {e}", flush=True)
        return None,None

    def get_route(self, olat,olon,dlat,dlon):
        try:
            r=requests.get(f"{self.OSRM}/route/v1/driving/{olon},{olat};{dlon},{dlat}",
                           params={"overview":"full","geometries":"geojson","steps":"true"},
                           timeout=30)
            if r.status_code==200:
                route=r.json()["routes"][0]
                coords=route["geometry"]["coordinates"]
                return coords, route["distance"]/1000, route["duration"]/60
        except Exception as e:
            print(f"  [ERR] OSRM: {e}", flush=True)
        return None,0,0

    def sample_points(self, coords, interval_km):
        if not coords: return []
        sampled=[coords[0]]
        accum=0.0
        for i in range(1,len(coords)):
            lon1,lat1=coords[i-1]; lon2,lat2=coords[i]
            dlat=math.radians(lat2-lat1); dlon=math.radians(lon2-lon1)
            a=math.sin(dlat/2)**2+math.cos(math.radians(lat1))*math.cos(math.radians(lat2))*math.sin(dlon/2)**2
            accum+=6371*2*math.atan2(math.sqrt(a),math.sqrt(1-a))
            if accum>=interval_km:
                sampled.append(coords[i]); accum=0.0
        if sampled[-1]!=coords[-1]: sampled.append(coords[-1])
        return sampled

    def road_type(self,idx,total):
        p=idx/max(total-1,1)
        return "urban" if p<0.12 or p>0.88 else "motorway" if 0.25<=p<=0.75 else "a_road"

    def speed_limit(self,rtype,vname):
        hgv="HGV" in vname
        return {"motorway":85 if hgv else 112,"a_road":60 if hgv else 90,"urban":48 if hgv else 50}.get(rtype,80)

# ============================================================================
# RUN ONE SIMULATION JOB
# ============================================================================

def run_job(job):
    job_id  = job["job_id"]
    logs    = []

    def p(msg, pct, status="running"):
        log(job_id, msg, logs)
        write_progress(job_id, status, pct, msg, list(logs))

    try:
        origin   = job["origin"]
        dest     = job["destination"]
        vtype    = job["vehicle"]
        weather  = job["weather"]
        tod      = job["time_of_day"]
        interval = float(job["sampling_interval_km"])
        loaded   = bool(job.get("loaded", False))
        scfg     = job.get("sensors",  {})
        pcfg     = job.get("physics",  {})

        vcfg = VEHICLES.get(vtype, VEHICLES["kia_niro_ev"])
        mass = vcfg.get("mass_loaded_kg", vcfg["mass_kg"]) if loaded else vcfg["mass_kg"]

        p(f"Job {job_id} received", 2)
        p(f"Vehicle : {vcfg['name']} ({mass:,} kg)", 4)
        p(f"Route   : {origin} → {dest}", 5)
        p(f"Weather : {weather}  |  Time: {tod}", 6)

        # ---- GEOCODING ----
        p("Geocoding origin...", 8)
        road = RoadNetwork()
        olat,olon = road.geocode(origin)
        if olat is None:
            raise RuntimeError(f"Geocoding failed for origin: '{origin}'")
        p(f"  Origin: {olat:.5f}, {olon:.5f}", 10)

        p("Geocoding destination...", 12)
        dlat,dlon = road.geocode(dest)
        if dlat is None:
            raise RuntimeError(f"Geocoding failed for destination: '{dest}'")
        p(f"  Destination: {dlat:.5f}, {dlon:.5f}", 14)

        # ---- OSRM ROUTE ----
        p("Fetching real route from OSRM...", 16)
        coords,dist_km,dur_min = road.get_route(olat,olon,dlat,dlon)
        if coords is None:
            raise RuntimeError("OSRM route fetch failed")
        p(f"  Route: {dist_km:.1f} km, {dur_min:.1f} min, {len(coords)} OSRM waypoints", 20)

        sampled = road.sample_points(coords, interval)
        p(f"  Sampled {len(sampled)} points at {interval} km intervals", 22)

        # ---- CREATE PHYSICS VEHICLE ----
        p("Creating PhysX vehicle in Isaac Sim world...", 25)
        vehicle = PhysicsVehicle(world, vcfg, mass)
        p(f"  PhysX vehicle created: {vcfg['name']}", 28)

        # ---- SENSOR OBJECTS ----
        cam_obj   = CameraSensor()
        lidar_obj = LiDARSensor()
        imu_obj   = IMUSensor()

        sf = scfg if isinstance(scfg,dict) else {}
        cam_flags = sf.get("camera",{})
        if isinstance(cam_flags,list): cam_flags={k:True for k in cam_flags}

        p(f"Sensors: camera={bool(cam_flags)}, lidar={sf.get('lidar')}, imu={sf.get('imu')}", 30)
        p(f"Physics: {[k for k,v in pcfg.items() if v]}", 32)
        p(f"Starting PhysX simulation over {len(sampled)} waypoints...", 35)

        # ---- SIMULATE ----
        trajectories = []
        for idx,(lon,lat) in enumerate(sampled):
            rtype  = road.road_type(idx, len(sampled))
            slimit = road.speed_limit(rtype, vcfg["name"])
            target = slimit * random.uniform(0.88, 0.99)

            lv,av,pos,spd,spdkmh = vehicle.step_to_speed(target, n=15)
            rq = {"motorway":8.8,"a_road":7.4,"urban":6.2}.get(rtype,7.0)+random.uniform(-0.4,0.4)

            cam_data   = cam_obj.simulate(weather,tod,rq) if cam_flags else None
            lidar_data = lidar_obj.simulate(weather,rtype) if sf.get("lidar") else None
            imu_data   = imu_obj.simulate(
                [(lv[0]-vehicle._prev_vel[0])/0.25,(lv[1]-vehicle._prev_vel[1])/0.25,0],
                av.tolist()
            ) if sf.get("imu") else None

            phys_data  = vehicle.compute_physics(lv,av,pos,spd,pcfg,rtype,weather)
            av_score,av_status = av_readiness(cam_data,lidar_data)

            point = {"lat":lat,"lon":lon,"speed_kmh":round(spdkmh,2),"speed_ms":round(spd,3),
                     "timestamp_s":idx*max(1,int(interval*3600/max(target,1))),
                     "road_type":rtype,"speed_limit_kmh":slimit,
                     "av_readiness_score":av_score,"av_readiness_status":av_status,
                     "quality_score":round(rq/10,3),
                     "sensor_confidence":round(
                         ((cam_data.get("sign_confidence",0) if cam_data else 0)+
                          (lidar_data.get("detection_confidence",0) if lidar_data else 0))/2,3)}
            if cam_data:   point["camera"]  = cam_data
            if lidar_data: point["lidar"]   = lidar_data
            if imu_data:   point["imu"]     = imu_data
            if phys_data:  point["physics"] = phys_data
            trajectories.append(point)

            # Progress update every 5 waypoints
            if (idx+1)%5==0 or idx==len(sampled)-1:
                pct = 35 + int(60*(idx+1)/len(sampled))
                p(f"  [{idx+1}/{len(sampled)}] {lat:.4f},{lon:.4f} | "
                  f"{spdkmh:.0f} km/h | {rtype} | AV:{av_status}", pct)

        # ---- BUILD RESULT ----
        p("Building scenario result...", 97)
        mean_av  = round(sum(t["av_readiness_score"] for t in trajectories)/len(trajectories),2)
        final_av = "GREEN" if mean_av>=7.5 else "AMBER" if mean_av>=5.0 else "RED"

        scenario = {
            "scenario_id": f"{origin}_{dest}_{weather}_{tod}_{vtype}".replace(" ","_").replace(",",""),
            "route":       f"{origin} to {dest}",
            "vehicle":     vcfg["name"],
            "vehicle_config": {**vcfg,"mass_used_kg":mass,"loaded":loaded},
            "road_type":      "mixed",
            "av_readiness":   final_av,
            "av_score_mean":  mean_av,
            "quality_score":  round(sum(t["quality_score"] for t in trajectories)/len(trajectories),3),
            "traffic_condition":"moderate",
            "weather_condition":weather,
            "time_of_day":    tod,
            "trajectories":   trajectories,
            "infrastructure": [],
            "incidents":      [],
            "metadata": {
                "origin":origin,"destination":dest,
                "distance_km":round(dist_km,2),"duration_min":round(dur_min,1),
                "total_osrm_waypoints":len(coords),"sampled_points":len(sampled),
                "sampling_interval_km":interval,
                "simulation_engine":"Isaac Sim 5.1 PhysX (persistent)",
                "coordinate_source":"OSRM + Nominatim (real GPS)",
                "physics_engine":"NVIDIA PhysX 5.x (DynamicCuboid)"
            }
        }

        # Write result file
        with open(result_path(job_id),"w") as f:
            json.dump({"status":"complete","scenario":scenario},f)

        p(f"COMPLETE — {len(trajectories)} waypoints | AV: {mean_av} ({final_av}) | {dist_km:.1f} km", 100, "complete")

    except Exception as e:
        err = traceback.format_exc()
        print(f"[JOB ERROR] {err}", flush=True)
        write_progress(job_id, "error", 0, f"ERROR: {str(e)}", logs + [err])
        with open(result_path(job_id),"w") as f:
            json.dump({"status":"error","error":str(e),"traceback":err},f)

# ============================================================================
# MAIN LOOP — poll for new jobs, stay alive forever
# ============================================================================

print("\n"+"="*70, flush=True)
print("  ISAAC SIM PERSISTENT SERVER — READY", flush=True)
print(f"  Isaac Sim initialised ONCE. Waiting for jobs.", flush=True)
print(f"  Job queue  : {JOBS_DIR}", flush=True)
print(f"  Progress   : {PROGRESS_DIR}", flush=True)
print(f"  Results    : {RESULTS_DIR}", flush=True)
print("="*70+"\n", flush=True)

# Create and keep a persistent physics world
world = World(stage_units_in_meters=1.0)
print("[OK] Physics world ready", flush=True)

# Write a ready flag so Flask knows Isaac Sim is up
ready_flag = os.path.join(QUEUE_DIR, "isaac_ready.flag")
with open(ready_flag,"w") as f:
    f.write(datetime.now().isoformat())

processed = set()

try:
    while True:
        # Scan for new job files
        try:
            job_files = [f for f in os.listdir(JOBS_DIR) if f.endswith(".json")]
        except Exception:
            job_files = []

        for fname in job_files:
            job_id = fname.replace(".json","")
            if job_id in processed:
                continue

            job_file = job_path(job_id)
            try:
                with open(job_file,"r") as f:
                    job = json.load(f)
            except Exception:
                continue

            print(f"\n[QUEUE] Picked up job: {job_id}", flush=True)
            processed.add(job_id)
            write_progress(job_id,"running",1,"Job accepted by Isaac Sim",[])

            run_job(job)

            # Clean up job file after processing
            try: os.remove(job_file)
            except Exception: pass

        # Keep physics world alive
        world.step(render=False)
        time.sleep(0.1)

except KeyboardInterrupt:
    print("\n[SHUTDOWN] Isaac Sim persistent server stopped", flush=True)
finally:
    simulation_app.close()
    print("[OK] Isaac Sim closed", flush=True)
