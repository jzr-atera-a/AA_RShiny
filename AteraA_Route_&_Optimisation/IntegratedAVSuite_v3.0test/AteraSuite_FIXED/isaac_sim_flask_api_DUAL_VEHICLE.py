"""
Atera Analytics - Isaac Sim Flask HTTP API  v3.0
Innovate UK Project 10153306 - CAM Pathfinder One

Designed for PERSISTENT Isaac Sim:
  - Isaac Sim starts ONCE via: C:/isaac-sim/python.bat isaac_sim_persistent_server.py
  - This Flask server runs standard Python (always lightweight, instant start)
  - R Shiny POSTs a job, gets back a job_id immediately
  - R Shiny polls GET /progress/<job_id> every second for live updates
  - Isaac Sim writes progress + result to shared files

Start order:
  1. C:/isaac-sim/python.bat isaac_sim_persistent_server.py   (wait for "READY")
  2. python isaac_sim_flask_api_DUAL_VEHICLE.py
  3. Launch R Shiny
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import json
import os
import uuid
import time
from datetime import datetime

app = Flask(__name__)
CORS(app)

# ============================================================================
# PATHS — must match isaac_sim_persistent_server.py
# ============================================================================

BASE_DIR     = os.path.dirname(os.path.abspath(__file__))
QUEUE_DIR    = os.path.join(BASE_DIR, "shared", "queue")
JOBS_DIR     = os.path.join(QUEUE_DIR, "jobs")
PROGRESS_DIR = os.path.join(QUEUE_DIR, "progress")
RESULTS_DIR  = os.path.join(QUEUE_DIR, "results")
READY_FLAG   = os.path.join(QUEUE_DIR, "isaac_ready.flag")

for d in [JOBS_DIR, PROGRESS_DIR, RESULTS_DIR]:
    os.makedirs(d, exist_ok=True)

# ============================================================================
# VEHICLE CONFIGS (duplicated here for /vehicles endpoint — no Isaac Sim needed)
# ============================================================================

VEHICLE_CONFIGS = {
    "kia_niro_ev": {
        "name":             "Kia Niro EV (2023-2025)",
        "category":         "Crossover SUV",
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
        "drive_type":       "FWD"
    },
    "renault_etech_t": {
        "name":             "Renault E-Tech T 42-tonne HGV",
        "category":         "Heavy Duty Truck",
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
        "drive_type":       "RWD"
    }
}

def isaac_ready():
    return os.path.exists(READY_FLAG)

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)

# ============================================================================
# ENDPOINTS
# ============================================================================

@app.route("/")
def index():
    return jsonify({
        "api":     "Atera Analytics Isaac Sim API",
        "version": "3.0.0 - Persistent Isaac Sim",
        "endpoints": {
            "GET  /status":              "Server + Isaac Sim readiness",
            "GET  /capabilities":        "Sensor + physics feature list",
            "GET  /vehicles":            "Vehicle configurations",
            "POST /scenarios/query":     "Submit simulation job → returns job_id immediately",
            "GET  /progress/<job_id>":   "Poll for live simulation progress",
            "GET  /result/<job_id>":     "Get completed simulation result"
        }
    })


@app.route("/status")
def status():
    ready = isaac_ready()
    ready_since = None
    if ready:
        try:
            with open(READY_FLAG) as f:
                ready_since = f.read().strip()
        except Exception:
            pass

    return jsonify({
        "status":               "online",
        "isaac_sim_ready":      ready,
        "isaac_sim_ready_since":ready_since,
        "isaac_sim_message":    "Isaac Sim persistent server running" if ready
                                else "Isaac Sim not started. Run: C:/isaac-sim/python.bat isaac_sim_persistent_server.py",
        "vehicles_available":   list(VEHICLE_CONFIGS.keys()),
        "server_time":          datetime.now().isoformat()
    })


@app.route("/capabilities")
def capabilities():
    return jsonify({
        "status": "success",
        "capabilities": {
            "sensors": {
                "Camera (RGB)":      True,
                "Camera (Depth)":    True,
                "Camera (Semantic)": True,
                "LiDAR":             True,
                "IMU":               True,
                "Contact Sensor":    True,
                "Radar":             False
            },
            "physics": {
                "Mass / Inertia":    True,
                "Linear Velocity":   True,
                "Angular Velocity":  True,
                "Acceleration":      True,
                "Momentum":          True,
                "Position":          True,
                "Wheel Dynamics":    True,
                "Suspension":        True,
                "Tire Friction":     True,
                "Braking System":    True,
                "Steering":          True,
                "Drivetrain":        True,
                "Aerodynamic Drag":  True,
                "Contact Forces":    True,
                "PhysX Vehicle API": True
            },
            "hardware": {
                "gpu_name":    "NVIDIA T500",
                "rtx_support": "Compatibility Mode",
                "cuda_cores":  896,
                "memory_mb":   4096,
                "sm_version":  "sm_75 (Turing)"
            },
            "software": {
                "isaac_sim_version": "5.1",
                "kit_version":       "107.3",
                "physx_version":     "5.x",
                "python_version":    "3.11",
                "server_mode":       "Persistent (single initialisation)"
            },
            "routing": {
                "osrm_endpoint":     "http://router.project-osrm.org",
                "geocoder":          "Nominatim (OpenStreetMap)",
                "coordinate_source": "Real GPS from OSRM routing"
            }
        }
    })


@app.route("/vehicles")
def get_all_vehicles():
    return jsonify({"count": len(VEHICLE_CONFIGS), "vehicles": VEHICLE_CONFIGS})


@app.route("/vehicles/<vehicle_id>")
def get_vehicle(vehicle_id):
    if vehicle_id in VEHICLE_CONFIGS:
        return jsonify(VEHICLE_CONFIGS[vehicle_id])
    return jsonify({"error": f"Unknown vehicle: {vehicle_id}"}), 404


@app.route("/scenarios/query", methods=["POST"])
def query_scenarios():
    """
    Submit a simulation job.
    Returns job_id IMMEDIATELY — does not wait for Isaac Sim.
    R Shiny then polls /progress/<job_id> for live updates.
    """
    if not isaac_ready():
        return jsonify({
            "error": "Isaac Sim persistent server is not running. "
                     "Start it with: C:/isaac-sim/python.bat isaac_sim_persistent_server.py"
        }), 503

    data = request.get_json(force=True) or {}
    log(f"POST /scenarios/query: {json.dumps(data)}")

    # Validate
    vehicle_type = data.get("vehicle", "kia_niro_ev")
    if vehicle_type not in VEHICLE_CONFIGS:
        return jsonify({"error": f"Invalid vehicle. Choose: {list(VEHICLE_CONFIGS.keys())}"}), 400

    origin      = (data.get("origin")      or "").strip()
    destination = (data.get("destination") or "").strip()
    if not origin or not destination:
        return jsonify({"error": "Both 'origin' and 'destination' required"}), 400

    # Build job
    job_id = str(uuid.uuid4())[:12]
    job = {
        "job_id":              job_id,
        "vehicle":             vehicle_type,
        "loaded":              bool(data.get("loaded", False)),
        "origin":              origin,
        "destination":         destination,
        "weather":             data.get("weather",              "clear"),
        "time_of_day":         data.get("time_of_day",          "day"),
        "sampling_interval_km":float(data.get("sampling_interval_km", 1.0)),
        "sensors":             data.get("sensors",  {}),
        "physics":             data.get("physics",  {}),
        "submitted_at":        datetime.now().isoformat()
    }

    # Write job file — Isaac Sim persistent server will pick it up
    job_file = os.path.join(JOBS_DIR, f"{job_id}.json")
    with open(job_file, "w") as f:
        json.dump(job, f, indent=2)

    log(f"Job {job_id} queued: {vehicle_type}, {origin}→{destination}")

    return jsonify({
        "job_id":     job_id,
        "status":     "queued",
        "message":    "Job submitted to Isaac Sim. Poll /progress/" + job_id + " for updates.",
        "poll_url":   f"/progress/{job_id}",
        "result_url": f"/result/{job_id}"
    })


@app.route("/progress/<job_id>")
def get_progress(job_id):
    """
    R Shiny polls this every second.
    Returns current status, percent complete, latest log lines.
    """
    progress_file = os.path.join(PROGRESS_DIR, f"{job_id}.json")

    if not os.path.exists(progress_file):
        # Check if job even exists
        job_file = os.path.join(JOBS_DIR, f"{job_id}.json")
        if os.path.exists(job_file):
            return jsonify({"job_id":job_id,"status":"queued","percent":0,
                            "message":"Waiting for Isaac Sim to pick up job...","log":[]})
        return jsonify({"error": f"Job {job_id} not found"}), 404

    try:
        with open(progress_file, "r") as f:
            data = json.load(f)
        return jsonify(data)
    except Exception as e:
        return jsonify({"job_id":job_id,"status":"running","percent":0,
                        "message":"Reading progress...","log":[]}), 200


@app.route("/result/<job_id>")
def get_result(job_id):
    """
    Returns full simulation result once complete.
    R Shiny calls this once /progress shows status=complete.
    """
    result_file = os.path.join(RESULTS_DIR, f"{job_id}.json")

    if not os.path.exists(result_file):
        # Check progress to give useful message
        progress_file = os.path.join(PROGRESS_DIR, f"{job_id}.json")
        if os.path.exists(progress_file):
            try:
                with open(progress_file) as f:
                    prog = json.load(f)
                return jsonify({"error": f"Not complete yet. Status: {prog.get('status')}, "
                                         f"{prog.get('percent',0)}%"}), 202
            except Exception:
                pass
        return jsonify({"error": f"Result for job {job_id} not found"}), 404

    try:
        with open(result_file, "r") as f:
            result = json.load(f)

        if result.get("status") == "error":
            return jsonify({"error": result.get("error", "Simulation failed"),
                            "traceback": result.get("traceback", "")}), 500

        scenario = result["scenario"]
        vc       = scenario.get("vehicle_config", VEHICLE_CONFIGS[scenario.get("vehicle","")] if scenario.get("vehicle","") in VEHICLE_CONFIGS else {})

        return jsonify({
            "count":            1,
            "scenarios":        [scenario],
            "vehicle_selected": scenario.get("vehicle",""),
            "vehicle_name":     vc.get("name",""),
            "vehicle_config":   vc,
            "route_info": {
                "origin":              scenario["metadata"]["origin"],
                "destination":         scenario["metadata"]["destination"],
                "distance_km":         scenario["metadata"]["distance_km"],
                "duration_min":        scenario["metadata"]["duration_min"],
                "sampling_interval_km":scenario["metadata"]["sampling_interval_km"]
            }
        })

    except Exception as e:
        return jsonify({"error": f"Failed to read result: {str(e)}"}), 500


# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    print("\n"+"="*70)
    print("  ATERA ANALYTICS - ISAAC SIM FLEET SIMULATION API  v3.0")
    print("  Persistent Isaac Sim Mode")
    print("="*70)
    print()
    print(f"  Isaac Sim ready: {'YES — ' + open(READY_FLAG).read().strip() if isaac_ready() else 'NO — start isaac_sim_persistent_server.py first'}")
    print()
    print(f"  POST /scenarios/query  → returns job_id instantly")
    print(f"  GET  /progress/<id>    → poll for live updates (1s interval)")
    print(f"  GET  /result/<id>      → fetch completed result")
    print()
    print(f"  Vehicles: {', '.join(VEHICLE_CONFIGS.keys())}")
    print(f"  Server  : http://0.0.0.0:5000")
    print("="*70+"\n")

    app.run(host="0.0.0.0", port=5000, debug=False, threaded=True)
