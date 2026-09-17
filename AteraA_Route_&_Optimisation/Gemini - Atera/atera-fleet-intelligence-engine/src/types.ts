export type VehicleType = 
  | 'Last-Mile EV' 
  | 'Regional Freight' 
  | 'Urban Delivery Van' 
  | 'Heavy EV Hauler';

export type VehicleStatus = 
  | 'On Route' 
  | 'Delayed (Weather)' 
  | 'Charging Depot B' 
  | 'Standby Depot A'
  | 'REROUTED (Bypassing Storm)' 
  | 'OPTIMIZED (Energy Efficient)' 
  | 'OPTIMIZED (Standard)'
  | 'STRANDED: Waterlogged in Zone B (Motor Lock)';

export interface VehicleTelemetry {
  vehicle_id: string;
  type: VehicleType;
  status: VehicleStatus;
  battery_pct: number;
  driver_hours_left: number;
  lat: number;
  lng: number;
  speed_mph: number;
  heading: number;
  destination: string;
  driver_name: string;
  depot?: string;
  vin?: string;
  lastPing?: string;
}

export interface RoutePoint {
  lat: number;
  lng: number;
  label?: string;
}

export interface HourlyChargingData {
  hour: string;
  hourNum: number;
  tariff: number;
  chargingBaseline: number;
  chargingOptimized: number;
  activeDemand: number;
  transformerLimitKw: number;
  headroomKw: number;
  isOverCapacity?: boolean;
}

export interface ScenarioMetrics {
  originalDistanceKm: number;
  optimizedDistanceKm: number;
  distanceDeltaKm: number;
  originalDurationMin: number;
  optimizedDurationMin: number;
  durationSavedMin: number;
  baselineEnergyKWh: number;
  optimizedEnergyKWh: number;
  energySavedKWh: number;
  baselineCost: number;
  optimizedCost: number;
  costSaved: number;
  carbonReductionKg: number;
}

export type PricingTierId = 'starter' | 'pro' | 'enterprise';

export interface PricingTier {
  id: PricingTierId;
  name: string;
  priceMonthly: number;
  priceAnnualMonthly: number;
  vehicleLimit: number;
  description: string;
  features: string[];
  popular?: boolean;
  active?: boolean;
}

export interface DataLineageSource {
  id: string;
  category: 'Weather' | 'Tariff' | 'Telemetry' | 'Traffic' | 'Routing' | 'Compliance';
  name: string;
  provider: string;
  endpoint: string;
  refreshInterval: string;
  lastSync: string;
  latencyMs: number;
  confidencePct: number;
  license: string;
}

export interface FilterState {
  search: string;
  type: string;
  status: string;
  batteryRange: 'all' | 'critical' | 'mid' | 'high';
  sortBy: 'vehicle_id' | 'battery_pct' | 'driver_hours_left' | 'speed_mph' | 'driver_name';
  sortOrder: 'asc' | 'desc';
  page: number;
  pageSize: number;
}
