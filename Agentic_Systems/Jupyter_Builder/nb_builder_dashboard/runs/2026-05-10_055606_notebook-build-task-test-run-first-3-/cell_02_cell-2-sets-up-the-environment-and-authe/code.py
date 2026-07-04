# ── Cell 2: Environment and Auth ──────────────────────────────────────────────
# Set up run directory from environment, authenticate to ArcGIS Online,
# and create curated Australian mines reference data

# Get RUN_DIR from environment variable
RUN_DIR = os.environ.get("RUN_DIR")
if RUN_DIR is None:
    raise EnvironmentError("RUN_DIR environment variable is not set")

print(f"RUN_DIR: {RUN_DIR}")

# Authenticate using locked profile pattern
gis = GIS(profile="josephzr")

# Validate authentication using gis.users.me (not gis.properties.user)
user = gis.users.me
print(f"Authenticated as: {user.username}")

# Create curated DataFrame of 8 Australian mine sites
australian_mines = pd.DataFrame({
    "mine_name": [
        "Olympic Dam",
        "Super Pit (Kalgoorlie)",
        "Mount Isa",
        "Argyle Diamond Mine",
        "Boddington Gold Mine",
        "Prominent Hill",
        "Pilbara Iron Ore",
        "Hunter Valley Coal"
    ],
    "commodity": [
        "Copper, Uranium, Gold",
        "Gold",
        "Copper, Lead, Zinc",
        "Diamonds",
        "Gold, Copper",
        "Copper, Gold",
        "Iron Ore",
        "Coal"
    ],
    "state": [
        "South Australia",
        "Western Australia",
        "Queensland",
        "Western Australia",
        "Western Australia",
        "South Australia",
        "Western Australia",
        "New South Wales"
    ],
    "latitude": [
        -30.4500,
        -30.7489,
        -20.7256,
        -16.7114,
        -32.7475,
        -29.7167,
        -22.3000,
        -32.3833
    ],
    "longitude": [
        136.8833,
        121.5031,
        139.4927,
        128.3903,
        116.8653,
        135.5333,
        118.5000,
        150.8833
    ],
    "status": [
        "Operating",
        "Operating",
        "Operating",
        "Closed (2020)",
        "Operating",
        "Operating",
        "Operating",
        "Operating"
    ]
})

print(f"Curated mines DataFrame: {len(australian_mines)} Australian sites")
print(australian_mines[["mine_name", "state", "commodity"]].to_string(index=False))
print("\nEnvironment and Auth OK")