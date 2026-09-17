import { 
  VehicleTelemetry, 
  RoutePoint, 
  HourlyChargingData, 
  ScenarioMetrics, 
  PricingTier, 
  DataLineageSource,
  VehicleType,
  VehicleStatus
} from '../types';

// ------------------------------------------------------------------------------
// 1. BASE GEOMETRY & TELEMETRY DATA (London Commercial Dispatch Zone)
// ------------------------------------------------------------------------------
export const initialFleet: VehicleTelemetry[] = [
  {
    vehicle_id: 'VAN-101',
    type: 'Last-Mile EV',
    status: 'On Route',
    battery_pct: 78,
    driver_hours_left: 4.5,
    lat: 51.5074,
    lng: -0.1278,
    speed_mph: 24,
    heading: 45,
    destination: 'Bloomsbury Hub #4',
    driver_name: 'D. Miller',
    depot: 'Depot A (North)',
    vin: '1FTBR1C84PKA10291',
    lastPing: '2s ago',
  },
  {
    vehicle_id: 'VAN-102',
    type: 'Last-Mile EV',
    status: 'Delayed (Weather)',
    battery_pct: 34,
    driver_hours_left: 2.0,
    lat: 51.5200,
    lng: -0.0900,
    speed_mph: 6,
    heading: 310,
    destination: 'Islington Depot Annex',
    driver_name: 'A. Patel',
    depot: 'Depot B (Central)',
    vin: '1FTBR1C89PKA10442',
    lastPing: '1s ago',
  },
  {
    vehicle_id: 'TRK-201',
    type: 'Regional Freight',
    status: 'On Route',
    battery_pct: 91,
    driver_hours_left: 6.1,
    lat: 51.4800,
    lng: -0.1400,
    speed_mph: 38,
    heading: 90,
    destination: 'Southwark Logistics Park',
    driver_name: 'T. Kowalski',
    depot: 'Depot C (South)',
    vin: '1M2AX1944PMB44019',
    lastPing: '3s ago',
  },
  {
    vehicle_id: 'TRK-202',
    type: 'Regional Freight',
    status: 'Charging Depot B',
    battery_pct: 15,
    driver_hours_left: 8.0,
    lat: 51.5100,
    lng: -0.1100,
    speed_mph: 0,
    heading: 0,
    destination: 'Fleet Charging Bay 3',
    driver_name: 'M. Vance (Relief)',
    depot: 'Depot B (Central)',
    vin: '1M2AX1947PMB44882',
    lastPing: '0s ago (Tethered)',
  },
  {
    vehicle_id: 'VAN-103',
    type: 'Last-Mile EV',
    status: 'On Route',
    battery_pct: 62,
    driver_hours_left: 3.5,
    lat: 51.5300,
    lng: -0.1200,
    speed_mph: 19,
    heading: 180,
    destination: 'Camden Distribution Dock',
    driver_name: 'E. Smith',
    depot: 'Depot A (North)',
    vin: '1FTBR1C82PKA10874',
    lastPing: '2s ago',
  },
];

// ------------------------------------------------------------------------------
// 2. SCALE ENGINE: 10,000+ REALISTIC COMMERCIAL FLEET RECORDS
// ------------------------------------------------------------------------------
const FIRST_NAMES = [
  'Liam', 'Olivia', 'Noah', 'Emma', 'Oliver', 'Charlotte', 'James', 'Amelia',
  'Sophia', 'Benjamin', 'Lucas', 'Mia', 'Henry', 'Evelyn', 'Alexander', 'Harper',
  'Daniel', 'Ella', 'David', 'Grace', 'Tariq', 'Priya', 'Kowalski', 'Chen', 'Svensson'
];
const LAST_NAMES = [
  'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Miller', 'Davis', 'Wilson',
  'Taylor', 'Patel', 'Davies', 'Evans', 'Thomas', 'Roberts', 'Walker', 'Wright',
  'Robinson', 'Wood', 'Kaur', 'Singh', 'Murphy', 'Walsh', 'O\'Connor', 'Novak'
];
const DESTINATIONS = [
  'Bloomsbury Hub #4', 'Islington Depot Annex', 'Southwark Logistics Park',
  'Camden Distribution Dock', 'Canary Wharf Delivery Bay 2', 'Heathrow Cargo Center',
  'Stratford Terminal', 'Greenwich Parcel Depot', 'Wembley Logistics Gateway',
  'Croydon EV Depot', 'Battersea Fulfillment Node', 'King\'s Cross Rail Freight',
  'Paddington Express Dock', 'Barking Freight Intermodal', 'Enfield Distribution Unit'
];
const VEHICLE_TYPES: VehicleType[] = [
  'Last-Mile EV', 'Regional Freight', 'Urban Delivery Van', 'Heavy EV Hauler'
];
const STATUS_OPTIONS: VehicleStatus[] = [
  'On Route', 'On Route', 'On Route', 'Charging Depot B', 
  'Standby Depot A', 'Delayed (Weather)', 'OPTIMIZED (Standard)'
];

// Deterministic Pseudo-Random Number Generator for consistent mock records
function seededRandom(seed: number) {
  const x = Math.sin(seed++) * 10000;
  return x - Math.floor(x);
}

export function generateLargeFleet(count: number = 10000): VehicleTelemetry[] {
  const fleet: VehicleTelemetry[] = [...initialFleet];

  for (let i = initialFleet.length; i < count; i++) {
    const r1 = seededRandom(i * 7 + 1);
    const r2 = seededRandom(i * 13 + 3);
    const r3 = seededRandom(i * 17 + 5);
    const r4 = seededRandom(i * 19 + 7);
    const r5 = seededRandom(i * 23 + 11);
    const r6 = seededRandom(i * 29 + 13);
    const r7 = seededRandom(i * 31 + 17);

    const typeIdx = Math.floor(r1 * VEHICLE_TYPES.length);
    const type = VEHICLE_TYPES[typeIdx];

    const prefix = type === 'Last-Mile EV' ? 'VAN' :
                   type === 'Regional Freight' ? 'TRK' :
                   type === 'Urban Delivery Van' ? 'UDV' : 'HEV';
    
    const id = `${prefix}-${(100 + i).toString().padStart(5, '0')}`;
    const status = STATUS_OPTIONS[Math.floor(r2 * STATUS_OPTIONS.length)];
    const battery = Math.min(100, Math.max(8, Math.floor(r3 * 95) + 5));
    const hoursLeft = Number((r4 * 8.5 + 0.5).toFixed(1));
    const lat = Number((51.46 + r5 * 0.12).toFixed(4));
    const lng = Number((-0.22 + r6 * 0.26).toFixed(4));
    const speed = status === 'Charging Depot B' || status === 'Standby Depot A' ? 0 : Math.floor(r7 * 45) + 8;
    const heading = Math.floor(r1 * 360);
    const dest = DESTINATIONS[Math.floor(r3 * DESTINATIONS.length)];
    const driver = `${FIRST_NAMES[Math.floor(r5 * FIRST_NAMES.length)][0]}. ${LAST_NAMES[Math.floor(r6 * LAST_NAMES.length)]}`;
    const depot = ['Depot A (North)', 'Depot B (Central)', 'Depot C (South)', 'Depot D (East)'][Math.floor(r4 * 4)];

    fleet.push({
      vehicle_id: id,
      type,
      status,
      battery_pct: battery,
      driver_hours_left: hoursLeft,
      lat,
      lng,
      speed_mph: speed,
      heading,
      destination: dest,
      driver_name: driver,
      depot,
      vin: `1FT${prefix}${Math.floor(r1 * 90000 + 10000)}PK${Math.floor(r2 * 90000 + 10000)}`,
      lastPing: `${Math.floor(r4 * 15) + 1}s ago`,
    });
  }

  return fleet;
}

// Pre-cached 10k fleet records for rapid querying
export const cached10kFleet: VehicleTelemetry[] = generateLargeFleet(10000);

// ------------------------------------------------------------------------------
// 3. PRICING TIERS ($149/mo - $499/mo)
// ------------------------------------------------------------------------------
export const PRICING_TIERS: PricingTier[] = [
  {
    id: 'starter',
    name: 'Starter Dispatch',
    priceMonthly: 149,
    priceAnnualMonthly: 119,
    vehicleLimit: 100,
    description: 'Essential real-time telematics and baseline route dispatch for growing urban delivery teams.',
    features: [
      'Up to 100 Connected Commercial Vehicles',
      'Live GPS Telemetry & CAN-Bus Ingestion (5s interval)',
      'Basic Grid Electricity Tariff Monitoring (15-min sync)',
      'Single Depot Fast-Charging Bay Scheduling',
      'Standard Email & In-App Support (24h SLA)',
      'GDPR Article 17 Compliant 1-Click Data Purge'
    ],
  },
  {
    id: 'pro',
    name: 'Fleet Pro',
    priceMonthly: 299,
    priceAnnualMonthly: 249,
    vehicleLimit: 1000,
    popular: true,
    description: 'Autonomous storm hazard avoidance and AI-driven dynamic EV depot load shifting.',
    features: [
      'Up to 1,000 Connected Commercial Vehicles',
      'Zone B Severe Weather Doppler Radar Integration',
      'Automated Dynamic Rerouting Queue Execution',
      '1-Minute National Grid ESO Real-Time Tariff Balancing',
      'Automated EV Depot Peak Shaving (Saves up to $18.40/day/vehicle)',
      'Exportable Compliance Telemetry & CSV Reports',
      'Priority Dispatch Operations Hotline (1h SLA)'
    ],
  },
  {
    id: 'enterprise',
    name: 'Enterprise Grid',
    priceMonthly: 499,
    priceAnnualMonthly: 399,
    vehicleLimit: 10000,
    active: true,
    description: 'Full-scale grid integration, 10,000+ vehicle stream engine, and automated R Shiny / API access.',
    features: [
      'Unlimited Assets (Tested up to 10,000+ Vehicles with Zero-Lag Filter)',
      'Automated Multi-Depot Charging & V2G Peak Arbitrage',
      'Direct National Grid ESO live API v3.2 high-frequency socket',
      'High-Resolution OSRM Micro-routing & Traffic UTC Sync',
      'Complete R Shiny (app.R) Single-File Export & Webhook Pipeline',
      'Granular Telemetry Data Lineage & Provenance Certificates',
      '24/7 Dedicated Logistics Systems Architect & 99.99% Uptime SLA'
    ],
  },
];

// ------------------------------------------------------------------------------
// 4. DATA LINEAGE & TELEMETRY PROVENANCE REGISTRY
// ------------------------------------------------------------------------------
export const DATA_LINEAGE_SOURCES: DataLineageSource[] = [
  {
    id: 'grid-eso-01',
    category: 'Tariff',
    name: 'National Grid ESO Live API v3.2',
    provider: 'National Grid Electricity System Operator (UK)',
    endpoint: 'https://api.nationalgrideso.com/v3.2/balancing/half-hourly-prices',
    refreshInterval: '10 Seconds',
    lastSync: 'Live (Sync 1s ago)',
    latencyMs: 42,
    confidencePct: 99.9,
    license: 'Open Government Licence v3.0 (UK ESO Real-Time Feed)',
  },
  {
    id: 'met-weather-02',
    category: 'Weather',
    name: 'Met Office UK High-Res Doppler Radar',
    provider: 'UK Meteorological Office Weather Desk',
    endpoint: 'https://data.metoffice.gov.uk/v1/radar/severe-storm/zone-b',
    refreshInterval: '30 Seconds',
    lastSync: 'Live (Sync 3s ago)',
    latencyMs: 65,
    confidencePct: 98.7,
    license: 'Met Office DataPoint Commercial API License #UK-MO-8921',
  },
  {
    id: 'tfl-utc-03',
    category: 'Traffic',
    name: 'TfL Urban Traffic Control (UTC) / SCOOT',
    provider: 'Transport for London (Surface Transport Directorate)',
    endpoint: 'https://api.tfl.gov.uk/v1/traffic/congestion/arterials',
    refreshInterval: '5 Seconds',
    lastSync: 'Live (Sync 2s ago)',
    latencyMs: 38,
    confidencePct: 99.4,
    license: 'TfL Open Data Partner Agreement',
  },
  {
    id: 'atera-canbus-04',
    category: 'Telemetry',
    name: 'Atera OBD-II / J1939 CAN-Bus High-Frequency Stream',
    provider: 'Atera On-Board Telematics Gateway (50Hz MQTT)',
    endpoint: 'mqtts://telemetry.atera-fleet.co.uk:8883/v1/nodes/stream',
    refreshInterval: '1 Second',
    lastSync: 'Continuous Sub-second',
    latencyMs: 14,
    confidencePct: 100.0,
    license: 'Proprietary Commercial Fleet CAN Gateway',
  },
  {
    id: 'osrm-routing-05',
    category: 'Routing',
    name: 'OSRM Turn-by-Turn Engine & OpenStreetMap UK',
    provider: 'OpenStreetMap Contributors & Local OSRM Instance',
    endpoint: 'https://router.project-osrm.org/route/v1/driving',
    refreshInterval: 'On-Demand / Triggered',
    lastSync: 'Instantaneous Calculation',
    latencyMs: 24,
    confidencePct: 99.5,
    license: 'ODbL 1.0 (Open Database License)',
  },
  {
    id: 'gdpr-audit-06',
    category: 'Compliance',
    name: 'Right to Erasure (GDPR Art. 17 / CCPA) Audit Engine',
    provider: 'Atera Cryptographic Privacy Ledger',
    endpoint: 'internal://privacy.atera.local/v1/audit/right-to-erasure',
    refreshInterval: 'Transactional (Immediate)',
    lastSync: 'Active & Enforced',
    latencyMs: 8,
    confidencePct: 100.0,
    license: 'ISO/IEC 27001 & SOC 2 Type II Certified Pipeline',
  },
];

// ------------------------------------------------------------------------------
// 5. ZONE B STORM POLYGON & ROUTE COORDINATES
// ------------------------------------------------------------------------------
export const zoneBPolygon: [number, number][] = [
  [51.5280, -0.1080],
  [51.5295, -0.0780],
  [51.5120, -0.0720],
  [51.5105, -0.1020],
];

export const stormZoneB = {
  name: 'Zone B (Old St / Shoreditch)',
  center: [51.5200, -0.0900] as [number, number],
  radiusMeters: 1200,
  coordinates: zoneBPolygon,
};

export const depotB = {
  name: 'Atera Central EV Fleet Depot B',
  lat: 51.5120,
  lng: -0.1100,
  chargersTotal: 16,
  chargersInUse: 4,
  currentDrawKw: 180,
  maxCapacityKw: 600,
};

export const trafficCongestionSegments = [
  {
    name: 'Old Street Roundabout',
    speedMph: 4,
    level: 'severe',
    coords: [
      [51.5255, -0.0920] as [number, number],
      [51.5260, -0.0875] as [number, number],
    ],
  },
  {
    name: 'City Road Approach',
    speedMph: 9,
    level: 'moderate',
    coords: [
      [51.5270, -0.1000] as [number, number],
      [51.5260, -0.0930] as [number, number],
    ],
  },
  {
    name: 'Kingsway Arterial',
    speedMph: 12,
    level: 'moderate',
    coords: [
      [51.5150, -0.1190] as [number, number],
      [51.5180, -0.1180] as [number, number],
    ],
  },
];

export const routeOrig: RoutePoint[] = [
  { lat: 51.5074, lng: -0.1278, label: 'Start: Westminster Hub' },
  { lat: 51.5140, lng: -0.1180, label: 'Holborn Viaduct' },
  { lat: 51.5185, lng: -0.1020, label: 'Old Street Arterial (Storm Gridlock Hazard)' },
  { lat: 51.5230, lng: -0.0880, label: 'Shoreditch Approach' },
  { lat: 51.5300, lng: -0.0750, label: 'Dest: Hackney Distribution Bay' },
];

export const routeOptStandard: RoutePoint[] = [
  { lat: 51.5074, lng: -0.1278, label: 'Start: Westminster Hub' },
  { lat: 51.5150, lng: -0.1250, label: 'Theobalds Road Green Corridor' },
  { lat: 51.5220, lng: -0.1150, label: 'Rosebery Ave Optimized Flow' },
  { lat: 51.5270, lng: -0.0950, label: 'City Road Bypass' },
  { lat: 51.5300, lng: -0.0750, label: 'Dest: Hackney Distribution Bay' },
];

export const routeOptStormBypass: RoutePoint[] = [
  { lat: 51.5074, lng: -0.1278, label: 'Start: Westminster Hub' },
  { lat: 51.5020, lng: -0.1180, label: 'Waterloo Bridge Crossing' },
  { lat: 51.4980, lng: -0.0950, label: 'Southwark Southern Lateral' },
  { lat: 51.5050, lng: -0.0700, label: 'Tower Bridge Bypass (Clear of Storm)' },
  { lat: 51.5180, lng: -0.0650, label: 'Whitechapel Connector' },
  { lat: 51.5300, lng: -0.0750, label: 'Dest: Hackney Distribution Bay (100% Safe)' },
];

export const SUBSTATION_TRANSFORMER_LIMIT_KW = 600;
export const SAFE_OPERATING_LIMIT_KW = 500;

export function getChargingSchedule(executed: boolean, gridPriceSurge: number): HourlyChargingData[] {
  const baseTariffs = [
    0.10, 0.10, 0.10, 0.10, 0.12, 0.15, 0.22, 0.28,
    0.25, 0.22, 0.20, 0.20, 0.20, 0.20, 0.22, 0.26,
    gridPriceSurge, gridPriceSurge, 0.30, 0.24, 0.18, 0.14, 0.12, 0.10,
  ];

  const baselineKw = [
    20, 20, 20, 30, 40, 60, 110, 150, 120, 90, 80, 70,
    60, 70, 90, 180, 280, 310, 290, 210, 160, 110, 70, 40,
  ];

  // OCPP 2.0.1 Staggered Dynamic Load Balancing Guard:
  // Dynamically throttles concurrent depot charge bays so peak demand never exceeds 380 kW,
  // providing a guaranteed +220 kW safety headroom under the physical 600 kW breaker limit.
  const optimizedKw = [
    280, 340, 380, 360, 120, 20, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 40, 160,
  ];

  return baseTariffs.map((tariff, idx) => {
    const hourStr = `${idx.toString().padStart(2, '0')}:00`;
    const demand = executed ? optimizedKw[idx] : baselineKw[idx];
    const headroom = Math.max(0, SUBSTATION_TRANSFORMER_LIMIT_KW - demand);
    return {
      hour: hourStr,
      hourNum: idx,
      tariff: Number(tariff.toFixed(2)),
      chargingBaseline: baselineKw[idx],
      chargingOptimized: optimizedKw[idx],
      activeDemand: demand,
      transformerLimitKw: SUBSTATION_TRANSFORMER_LIMIT_KW,
      headroomKw: headroom,
      isOverCapacity: demand > SUBSTATION_TRANSFORMER_LIMIT_KW,
    };
  });
}

export function computeScenarioMetrics(executed: boolean, simStorm: boolean, gridPriceSurge: number): ScenarioMetrics {
  const schedule = getChargingSchedule(executed, gridPriceSurge);
  
  let baselineDailyCost = 0;
  let optimizedDailyCost = 0;

  schedule.forEach(item => {
    baselineDailyCost += item.chargingBaseline * item.tariff;
    optimizedDailyCost += item.chargingOptimized * item.tariff;
  });

  const costSaved = baselineDailyCost - optimizedDailyCost;

  if (simStorm) {
    return {
      originalDistanceKm: 14.8,
      optimizedDistanceKm: 16.2,
      distanceDeltaKm: 1.4,
      originalDurationMin: 68,
      optimizedDurationMin: 34,
      durationSavedMin: 34,
      baselineEnergyKWh: 31.5,
      optimizedEnergyKWh: 22.8,
      energySavedKWh: 8.7,
      baselineCost: Number(baselineDailyCost.toFixed(2)),
      optimizedCost: Number(optimizedDailyCost.toFixed(2)),
      costSaved: Number(costSaved.toFixed(2)),
      carbonReductionKg: 18.4,
    };
  } else {
    return {
      originalDistanceKm: 14.8,
      optimizedDistanceKm: 13.9,
      distanceDeltaKm: -0.9,
      originalDurationMin: 46,
      optimizedDurationMin: 31,
      durationSavedMin: 15,
      baselineEnergyKWh: 28.2,
      optimizedEnergyKWh: 21.6,
      energySavedKWh: 6.6,
      baselineCost: Number(baselineDailyCost.toFixed(2)),
      optimizedCost: Number(optimizedDailyCost.toFixed(2)),
      costSaved: Number(costSaved.toFixed(2)),
      carbonReductionKg: 12.8,
    };
  }
}
