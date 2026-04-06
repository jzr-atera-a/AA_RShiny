"""
Atera Analytics - Isaac Sim PhysX Dual Vehicle Simulation
Innovate UK Project 10153306 - CAM Pathfinder One

Called as subprocess by isaac_sim_flask_api_DUAL_VEHICLE.py
Runs inside C:/isaac-sim/python.bat environment

Outputs:
  JSON file with full trajectory, sensor data, and physics state
  per waypoint - only for features the user selected in R Shiny.
"""

from omni.isaac.kit import SimulationApp

simulation_app = SimulationApp({
    "headless":     True,
    "width":        1,
    "height":       1,
    "renderer":     "RayTracedLighting",
    "active_gpu":   0,
    "multi_gpu":    False,
    "physics_gpu":  0,
    "anti_aliasing": 0
})

from omni.isaac.core import World
from omni.isaac.core.objects import DynamicCuboid
import numpy as np
import requests
import json
import argparse
import random
import math
import sys

print("="*70)
print("  ISAAC SIM PHYSX - DUAL VEHICLE SIMULATION")
print("  Kia Niro EV | Renault E-Tech T 42-tonne HGV")
print("="*70, flush=True)

world = World(stage_units_in_meters=1.0)
print("[OK] Physics world created", flush=True)

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
        weather_delta = {"clear":0, "light_rain":-1.5, "heavy_rain":-3.5, "fog":-4.5, "snow":-5.0}
        time_delta    = {"day":0, "dusk":-1.2, "night":-2.5}
        score = road_quality + weather_delta.get(weather, 0) + time_delta.get(time_of_day, 0)
        score += random.uniform(-0.3, 0.3)
        lane_vis  = max(0.0, min(10.0, score))
        sign_conf = max(0.0, min(1.0, 0.97 + weather_delta.get(weather,0)*0.04 + random.uniform(-0.03,0.03)))
        obj_det   = max(0.0, min(1.0, 0.93 + weather_delta.get(weather,0)*0.03 + random.uniform(-0.02,0.02)))
        return {
            "lane_visibility":        round(lane_vis, 2),
            "sign_confidence":        round(sign_conf, 3),
            "object_detection_conf":  round(obj_det, 3)
        }


class LiDARSensor:
    def simulate(self, weather, road_type):
        base     = {"motorway":850,"a_road":750,"urban":640}.get(road_type,750)
        factor   = {"clear":1.0,"light_rain":0.86,"heavy_rain":0.64,"fog":0.48,"snow":0.42}.get(weather,1.0)
        density  = base * factor + random.uniform(-40, 40)
        det_conf = max(0.0, min(1.0, min(0.96, density/1000.0) + random.uniform(-0.04,0.04)))
        range_m  = max(20, 120 * factor + random.uniform(-5, 5))
        return {
            "point_density":        round(density, 1),
            "detection_confidence": round(det_conf, 3),
            "effective_range_m":    round(range_m,  1)
        }


class IMUSensor:
    def simulate(self, accel_ms2, angular_vel):
        noise = 0.01
        return {
            "accel_x": round(accel_ms2[0] + random.gauss(0, noise), 4),
            "accel_y": round(accel_ms2[1] + random.gauss(0, noise), 4),
            "accel_z": round(accel_ms2[2] + random.gauss(0, noise) + 9.81, 4),
            "gyro_x":  round(angular_vel[0] + random.gauss(0,0.001), 5),
            "gyro_y":  round(angular_vel[1] + random.gauss(0,0.001), 5),
            "gyro_z":  round(angular_vel[2] + random.gauss(0,0.001), 5)
        }


def calculate_av_readiness(cam_data, lidar_data):
    lane_vis   = cam_data.get("lane_visibility",       5.0) if cam_data else 5.0
    lidar_dens = lidar_data.get("point_density",        500) if lidar_data else 500
    cam_conf   = cam_data.get("sign_confidence",        0.5) if cam_data else 0.5
    lidar_conf = lidar_data.get("detection_confidence", 0.5) if lidar_data else 0.5
    score = ((lane_vis/10)*0.3 + (lidar_dens/1000)*0.3 + cam_conf*0.2 + lidar_conf*0.2) * 10
    score = max(0.0, min(10.0, score + random.uniform(-0.1, 0.1)))
    status = "GREEN" if score >= 7.5 else "AMBER" if score >= 5.0 else "RED"
    return round(score, 2), status

# ============================================================================
# PHYSICS VEHICLE
# ============================================================================

class PhysicsVehicle:
    def __init__(self, world_obj, vcfg, mass_override=None):
        self.config = vcfg
        self.mass   = mass_override or vcfg["mass_kg"]
        self._prev_velocity = np.zeros(3)
        self._dt = 1.0 / 60.0

        self.prim = DynamicCuboid(
            prim_path="/World/Vehicle",
            name="vehicle_body",
            position=np.array([0.0, 0.0, vcfg["height_m"] / 2.0 + 0.1]),
            size=1.0,
            scale=np.array([vcfg["width_m"], vcfg["length_m"], vcfg["height_m"]]),
            mass=float(self.mass)
        )
        world_obj.scene.add(self.prim)
        world_obj.reset()
        print(f"[OK] PhysX vehicle: {vcfg['name']} ({self.mass:,} kg)", flush=True)

    def get_state(self):
        lv = np.array(self.prim.get_linear_velocity())
        av = np.array(self.prim.get_angular_velocity())
        pos, _ = self.prim.get_world_pose()
        pos = np.array(pos)
        spd_ms  = float(np.linalg.norm(lv))
        spd_kmh = spd_ms * 3.6
        return lv, av, pos, spd_ms, spd_kmh

    def step_to_speed(self, target_kmh, n_steps=15):
        target_ms = target_kmh / 3.6
        max_force = min(self.config["power_kw"] * 1000 / max(target_ms, 1.0), self.mass * 5.0)
        for _ in range(n_steps):
            lv, _, _, spd_ms, _ = self.get_state()
            diff    = target_ms - spd_ms
            force_x = float(np.clip(diff * self.mass * 0.5, -max_force, max_force))
            self.prim.apply_force(np.array([force_x, 0.0, 0.0]))
            world.step(render=False)
        return self.get_state()

    def compute_physics(self, lin_vel, ang_vel, pos, speed_ms, pcfg, target_kmh, rtype, weather):
        result = {}
        cfg = self.config
        dt  = self._dt * 15

        if pcfg.get("velocity"):
            result["linear_velocity_ms"] = [round(float(v), 4) for v in lin_vel]
            result["speed_ms"]  = round(speed_ms, 3)
            result["speed_kmh"] = round(speed_ms * 3.6, 2)

        if pcfg.get("angular_velocity"):
            result["angular_velocity_rads"] = [round(float(v), 5) for v in ang_vel]
            result["yaw_rate_degs"]          = round(math.degrees(float(ang_vel[2])), 3)

        if pcfg.get("position"):
            result["position_m"] = [round(float(p), 3) for p in pos]

        accel = np.zeros(3)
        if pcfg.get("acceleration"):
            accel = (lin_vel - self._prev_velocity) / dt if dt > 0 else np.zeros(3)
            result["acceleration_ms2"]       = [round(float(a), 4) for a in accel]
            result["acceleration_g"]         = round(float(np.linalg.norm(accel)) / 9.81, 4)
            result["longitudinal_accel_ms2"] = round(float(accel[0]), 4)
            result["lateral_accel_ms2"]      = round(float(accel[1]), 4)

        if pcfg.get("momentum"):
            mom = lin_vel * self.mass
            result["momentum_kgms"]      = [round(float(m), 2) for m in mom]
            result["momentum_magnitude"] = round(float(np.linalg.norm(mom)), 2)

        if pcfg.get("mass_inertia"):
            w, l, h = cfg["width_m"], cfg["length_m"], cfg["height_m"]
            result["mass_kg"]     = self.mass
            result["inertia_ixx"] = round((1/12)*self.mass*(h**2+l**2), 1)
            result["inertia_iyy"] = round((1/12)*self.mass*(w**2+h**2), 1)
            result["inertia_izz"] = round((1/12)*self.mass*(w**2+l**2), 1)

        if pcfg.get("aerodynamics"):
            rho  = 1.225
            drag = 0.5 * rho * cfg["drag_coefficient"] * cfg["frontal_area_m2"] * speed_ms**2
            result["aerodynamic_drag_N"] = round(drag, 1)
            result["aero_drag_power_kW"] = round(drag * speed_ms / 1000.0, 3)
            result["drag_coefficient"]   = cfg["drag_coefficient"]
            result["frontal_area_m2"]    = cfg["frontal_area_m2"]

        if pcfg.get("tire_friction"):
            mu = cfg["tire_mu_wet"] if weather in ["light_rain","heavy_rain"] else \
                 cfg["tire_mu_ice"] if weather in ["ice","snow"] else cfg["tire_mu_dry"]
            nfw = (self.mass * 9.81) / 4.0
            result["tire_friction_coeff"]  = round(mu, 3)
            result["max_friction_force_N"] = round(mu * nfw, 1)
            result["normal_force_per_wheel_N"] = round(nfw, 1)

        if pcfg.get("suspension"):
            stat = (self.mass * 9.81 / 4.0) / cfg["spring_k"]
            dyn  = float(abs(accel[2])) * self.mass / (4.0 * cfg["spring_k"])
            result["suspension_static_deflection_m"] = round(stat, 4)
            result["suspension_dynamic_delta_m"]     = round(dyn,  5)
            result["spring_rate_Nm"]  = cfg["spring_k"]
            result["damper_rate_Nsm"] = cfg["damper_c"]

        if pcfg.get("braking"):
            brake_f  = max(0.0, -float(accel[0])) * self.mass
            max_b    = cfg["tire_mu_dry"] * self.mass * 9.81
            result["braking_force_N"]     = round(brake_f, 1)
            result["max_braking_force_N"] = round(max_b,   1)
            result["braking_decel_ms2"]   = round(brake_f / max(self.mass,1), 4)

        if pcfg.get("drivetrain"):
            wr  = cfg["wheel_radius_m"]
            rpm = (speed_ms / wr) * 60.0 / (2 * math.pi)
            tf  = cfg["power_kw"] * 1000 / max(speed_ms, 0.1)
            result["wheel_speed_rpm"]  = round(rpm, 1)
            result["tractive_force_N"] = round(min(tf, self.mass*9.81), 1)
            result["power_demand_kW"]  = round(cfg["power_kw"] * min(1.0, speed_ms/(cfg["max_speed_kmh"]/3.6)), 1)

        if pcfg.get("steering"):
            yr  = float(ang_vel[2])
            sa  = math.degrees(math.atan2(yr * cfg["wheelbase_m"], max(speed_ms, 0.1)))
            result["steering_angle_deg"] = round(sa, 3)
            result["yaw_rate_rads"]      = round(yr, 5)
            result["turning_radius_m"]   = round(speed_ms / max(abs(yr), 1e-6), 2) if abs(yr) > 1e-4 else None

        if pcfg.get("wheels"):
            wr  = cfg["wheel_radius_m"]
            rpm = (speed_ms / wr) * 60.0 / (2 * math.pi)
            result["wheel_speed_rpm"]   = round(rpm, 1)
            result["longitudinal_slip"] = round(random.uniform(0.0, 0.05), 4)
            result["wheel_radius_m"]    = wr

        if pcfg.get("contact_forces"):
            normal = self.mass * 9.81
            llt    = self.mass * float(abs(accel[1])) * cfg.get("cog_height_m", 0.6) / cfg["width_m"]
            result["normal_force_N"]          = round(normal, 1)
            result["lateral_load_transfer_N"] = round(llt,    1)

        self._prev_velocity = lin_vel.copy()
        return result

# ============================================================================
# ROUTING
# ============================================================================

class RoadNetwork:
    def __init__(self):
        self.osrm = "http://router.project-osrm.org"

    def geocode(self, location):
        url    = "https://nominatim.openstreetmap.org/search"
        params = {"q": location, "format": "json", "limit": 1}
        hdrs   = {"User-Agent": "AteraAnalytics-IsaacSim/2.0"}
        try:
            r = requests.get(url, params=params, headers=hdrs, timeout=10)
            if r.status_code == 200 and r.json():
                res = r.json()[0]
                lat, lon = float(res["lat"]), float(res["lon"])
                print(f"  [OK] Geocoded '{location}': {lat:.5f}, {lon:.5f}", flush=True)
                return lat, lon
        except Exception as e:
            print(f"  [ERR] Geocode: {e}", flush=True)
        return None, None

    def get_route(self, olat, olon, dlat, dlon):
        url    = f"{self.osrm}/route/v1/driving/{olon},{olat};{dlon},{dlat}"
        params = {"overview":"full","geometries":"geojson","steps":"true"}
        try:
            r = requests.get(url, params=params, timeout=30)
            if r.status_code == 200:
                route  = r.json()["routes"][0]
                coords = route["geometry"]["coordinates"]
                dist   = route["distance"] / 1000.0
                dur    = route["duration"] / 60.0
                print(f"  [OK] OSRM: {dist:.1f} km, {dur:.1f} min, {len(coords)} pts", flush=True)
                return coords, dist, dur
        except Exception as e:
            print(f"  [ERR] OSRM: {e}", flush=True)
        return None, 0, 0

    def sample_points(self, coords, interval_km):
        if not coords:
            return []
        sampled = [coords[0]]
        accum   = 0.0
        for i in range(1, len(coords)):
            lon1, lat1 = coords[i-1]
            lon2, lat2 = coords[i]
            dlat = math.radians(lat2 - lat1)
            dlon = math.radians(lon2 - lon1)
            a    = math.sin(dlat/2)**2 + math.cos(math.radians(lat1))*math.cos(math.radians(lat2))*math.sin(dlon/2)**2
            dist = 6371.0 * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
            accum += dist
            if accum >= interval_km:
                sampled.append(coords[i])
                accum = 0.0
        if sampled[-1] != coords[-1]:
            sampled.append(coords[-1])
        print(f"  [OK] Sampled {len(sampled)} points at {interval_km} km intervals", flush=True)
        return sampled

    def road_type(self, idx, total):
        p = idx / max(total-1, 1)
        if p < 0.12 or p > 0.88: return "urban"
        elif 0.25 <= p <= 0.75:  return "motorway"
        else:                     return "a_road"

    def speed_limit(self, rtype, vehicle_name):
        is_hgv = "HGV" in vehicle_name
        return {"motorway": 85 if is_hgv else 112,
                "a_road":   60 if is_hgv else 90,
                "urban":    48 if is_hgv else 50}.get(rtype, 80)

# ============================================================================
# MAIN
# ============================================================================

def run_simulation(origin, dest, vehicle_type, weather, time_of_day,
                   sampling_interval_km, sensors_cfg, physics_cfg, loaded=False):

    vcfg = VEHICLES.get(vehicle_type, VEHICLES["kia_niro_ev"])
    mass = vcfg.get("mass_loaded_kg", vcfg["mass_kg"]) if loaded else vcfg["mass_kg"]

    print(f"\n{'='*60}", flush=True)
    print(f"Vehicle  : {vcfg['name']} ({mass:,} kg)", flush=True)
    print(f"Route    : {origin} -> {dest}", flush=True)
    print(f"Weather  : {weather}  Time: {time_of_day}", flush=True)
    print(f"Physics  : {[k for k,v in physics_cfg.items() if v]}", flush=True)
    print(f"{'='*60}\n", flush=True)

    cam_obj   = CameraSensor()
    lidar_obj = LiDARSensor()
    imu_obj   = IMUSensor()
    road      = RoadNetwork()

    olat, olon = road.geocode(origin)
    dlat, dlon = road.geocode(dest)
    if olat is None or dlat is None:
        print("[FATAL] Geocoding failed", flush=True)
        return None

    coords, dist_km, dur_min = road.get_route(olat, olon, dlat, dlon)
    if coords is None:
        print("[FATAL] OSRM failed", flush=True)
        return None

    sampled = road.sample_points(coords, sampling_interval_km)
    if not sampled:
        print("[FATAL] No sampled points", flush=True)
        return None

    vehicle = PhysicsVehicle(world, vcfg, mass_override=mass)

    print(f"\n[SIM] {len(sampled)} waypoints to simulate...", flush=True)
    trajectories = []

    for idx, (lon, lat) in enumerate(sampled):
        rtype  = road.road_type(idx, len(sampled))
        slimit = road.speed_limit(rtype, vcfg["name"])
        target = slimit * random.uniform(0.88, 0.99)

        lin_vel, ang_vel, pos, spd_ms, spd_kmh = vehicle.step_to_speed(target, n_steps=15)

        road_quality = {"motorway":8.8,"a_road":7.4,"urban":6.2}.get(rtype,7.0) + random.uniform(-0.4,0.4)

        # Build sensor flags from whatever format R sends
        sf        = sensors_cfg if isinstance(sensors_cfg, dict) else {}
        cam_flags = sf.get("camera", {})
        if isinstance(cam_flags, list): cam_flags = {k:True for k in cam_flags}

        cam_data   = cam_obj.simulate(weather, time_of_day, road_quality) if cam_flags else None
        lidar_data = lidar_obj.simulate(weather, rtype) if sf.get("lidar") else None
        accel_imu  = [(lin_vel[0]-vehicle._prev_velocity[0])/0.25,
                      (lin_vel[1]-vehicle._prev_velocity[1])/0.25, 0.0]
        imu_data   = imu_obj.simulate(accel_imu, ang_vel.tolist()) if sf.get("imu") else None

        phys_data  = vehicle.compute_physics(lin_vel, ang_vel, pos, spd_ms,
                                              physics_cfg, target, rtype, weather)

        av_score, av_status = calculate_av_readiness(cam_data, lidar_data)

        point = {
            "lat":                 lat,
            "lon":                 lon,
            "speed_kmh":           round(spd_kmh, 2),
            "speed_ms":            round(spd_ms,  3),
            "timestamp_s":         idx * max(1, int(sampling_interval_km*3600/max(target,1))),
            "road_type":           rtype,
            "speed_limit_kmh":     slimit,
            "av_readiness_score":  av_score,
            "av_readiness_status": av_status,
            "quality_score":       round(road_quality/10.0, 3),
            "sensor_confidence":   round(
                ((cam_data.get("sign_confidence",0) if cam_data else 0) +
                 (lidar_data.get("detection_confidence",0) if lidar_data else 0)) / 2, 3
            )
        }
        if cam_data:   point["camera"]  = cam_data
        if lidar_data: point["lidar"]   = lidar_data
        if imu_data:   point["imu"]     = imu_data
        if phys_data:  point["physics"] = phys_data

        trajectories.append(point)

        if (idx+1) % 10 == 0 or idx == len(sampled)-1:
            print(f"  [{idx+1:3d}/{len(sampled)}] {lat:.5f},{lon:.5f}  "
                  f"{spd_kmh:.1f}km/h  {rtype}  {av_status}", flush=True)

    mean_av   = round(sum(t["av_readiness_score"] for t in trajectories)/len(trajectories), 2)
    final_av  = "GREEN" if mean_av>=7.5 else "AMBER" if mean_av>=5.0 else "RED"

    scenario = {
        "scenario_id":      f"{origin}_{dest}_{weather}_{time_of_day}_{vehicle_type}".replace(" ","_").replace(",",""),
        "route":            f"{origin} to {dest}",
        "vehicle":          vcfg["name"],
        "vehicle_config":   {**vcfg, "mass_used_kg": mass, "loaded": loaded},
        "road_type":        "mixed",
        "av_readiness":     final_av,
        "av_score_mean":    mean_av,
        "quality_score":    round(sum(t["quality_score"] for t in trajectories)/len(trajectories), 3),
        "traffic_condition":"moderate",
        "weather_condition":weather,
        "time_of_day":      time_of_day,
        "trajectories":     trajectories,
        "infrastructure":   [],
        "incidents":        [],
        "metadata": {
            "origin":               origin,
            "destination":          dest,
            "distance_km":          round(dist_km, 2),
            "duration_min":         round(dur_min, 1),
            "total_osrm_waypoints": len(coords),
            "sampled_points":       len(sampled),
            "sampling_interval_km": sampling_interval_km,
            "simulation_engine":    "Isaac Sim 5.1 PhysX",
            "coordinate_source":    "OSRM + Nominatim (real GPS)",
            "physics_engine":       "NVIDIA PhysX 5.x (DynamicCuboid)"
        }
    }

    print(f"\n[OK] Done - {len(trajectories)} pts, AV mean={mean_av} ({final_av})", flush=True)
    return scenario


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--origin",            required=True)
    parser.add_argument("--dest",              required=True)
    parser.add_argument("--vehicle",           default="kia_niro_ev")
    parser.add_argument("--weather",           default="clear")
    parser.add_argument("--time",              default="day")
    parser.add_argument("--sampling-interval", type=float, default=1.0)
    parser.add_argument("--config",            required=True)
    parser.add_argument("--output",            default="scenario_output.json")
    args = parser.parse_args()

    with open(args.config, "r") as f:
        cfg = json.load(f)

    scenario = run_simulation(
        origin=args.origin, dest=args.dest,
        vehicle_type=args.vehicle, weather=args.weather,
        time_of_day=args.time,
        sampling_interval_km=args.sampling_interval,
        sensors_cfg=cfg.get("sensors", {}),
        physics_cfg=cfg.get("physics", {}),
        loaded=cfg.get("loaded", False)
    )

    if scenario:
        with open(args.output, "w") as f:
            json.dump(scenario, f, indent=2)
        print(f"\n[OK] Saved: {args.output}", flush=True)
    else:
        print("\n[FATAL] No scenario data generated", flush=True)
        sys.exit(1)

    simulation_app.close()
    print("[OK] Isaac Sim closed", flush=True)
