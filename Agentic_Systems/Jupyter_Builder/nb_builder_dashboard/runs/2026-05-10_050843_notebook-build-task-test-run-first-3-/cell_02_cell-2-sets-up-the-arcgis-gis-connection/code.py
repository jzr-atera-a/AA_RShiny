# ── Cell 2: Environment and Auth ──────────────────────────────────────────────
import sys

# Read RUN_DIR from environment
RUN_DIR = os.environ.get('RUN_DIR', '.')
print(f"RUN_DIR: {RUN_DIR}", flush=True)

# LOCKED auth pattern - do not modify
print("Connecting to ArcGIS Online...", flush=True)
gis = GIS(profile='josephzr')

# Verify authentication using gis.users.me (not gis.properties.user)
user = gis.users.me
if user is None:
    raise RuntimeError(
        "Authentication failed: gis.users.me returned None. "
        "Profile 'josephzr' may be missing credentials in keyring. "
        "Run: GIS(profile='josephzr', password='YOUR_PASSWORD') once to store credentials."
    )
print(f"Authenticated as: {user.username}", flush=True)

# Curated Australian mines DataFrame (8 sites)
mines_data = {
    'name': [
        'Olympic Dam',
        'Super Pit (Kalgoorlie)',
        'Mount Isa',
        'Argyle Diamond Mine',
        'Ranger Uranium Mine',
        'Boddington Gold Mine',
        'Cannington Mine',
        'Cadia Valley Operations'
    ],
    'latitude': [
        -30.4500,
        -30.7749,
        -20.7256,
        -16.7114,
        -12.6833,
        -32.7500,
        -21.8750,
        -33.4667
    ],
    'longitude': [
        136.8833,
        121.5074,
        139.4927,
        128.3989,
        132.9167,
        116.3667,
        140.9167,
        148.9833
    ],
    'commodity': [
        'Copper, Uranium, Gold',
        'Gold',
        'Copper, Lead, Zinc',
        'Diamonds',
        'Uranium',
        'Gold, Copper',
        'Silver, Lead, Zinc',
        'Gold, Copper'
    ]
}

mines_df = pd.DataFrame(mines_data)
print(f"\nCurated mines dataset: {len(mines_df)} Australian sites", flush=True)
print(mines_df[['name', 'commodity']].to_string(index=False), flush=True)

print("\n✅ Environment and Auth complete", flush=True)
sys.stdout.flush()