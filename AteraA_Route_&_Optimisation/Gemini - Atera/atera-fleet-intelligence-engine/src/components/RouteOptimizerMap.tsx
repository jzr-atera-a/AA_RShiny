import React, { useEffect, useRef, useState, useCallback } from 'react';
import L from 'leaflet';
import { RoutePoint, ScenarioMetrics } from '../types';
import { routeOrig, stormZoneB } from '../data/fleetData';
import { CheckCircle, Clock, Navigation, Zap, AlertCircle, ShieldCheck, Settings } from 'lucide-react';
import { MapConfigModal, BasemapMode } from './MapConfigModal';

interface RouteOptimizerMapProps {
  activeRoute: RoutePoint[];
  executed: boolean;
  executedAt: string | null;
  simStorm: boolean;
  metrics: ScenarioMetrics;
}

// Procedural Thames River geometry for offline resilient vector basemap
const thamesCoordinates: [number, number][] = [
  [51.4850, -0.1900],
  [51.4820, -0.1600],
  [51.4860, -0.1300],
  [51.5030, -0.1200],
  [51.5080, -0.1100],
  [51.5085, -0.0900],
  [51.5040, -0.0750],
  [51.5020, -0.0500],
  [51.5080, -0.0200],
  [51.5000, 0.0000],
];

const londonArterials: [number, number][][] = [
  [[51.5140, -0.1600], [51.5160, -0.1300], [51.5170, -0.1000], [51.5190, -0.0600]],
  [[51.5250, -0.1190], [51.5170, -0.1190], [51.5060, -0.1170], [51.4980, -0.1100]],
  [[51.5320, -0.1050], [51.5260, -0.0920], [51.5190, -0.0860]],
];

export const RouteOptimizerMap: React.FC<RouteOptimizerMapProps> = ({
  activeRoute,
  executed,
  executedAt,
  simStorm,
  metrics,
}) => {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const currentTileLayerRef = useRef<L.TileLayer | null>(null);
  const offlineVectorLayerRef = useRef<L.LayerGroup | null>(null);
  const routesLayerRef = useRef<L.LayerGroup | null>(null);
  const hazardLayerRef = useRef<L.LayerGroup | null>(null);

  // Basemap Guard State
  const [basemapMode, setBasemapMode] = useState<BasemapMode>('keyless-dark-osm');
  const [apiKey, setApiKey] = useState<string>('');
  const [isConfigModalOpen, setIsConfigModalOpen] = useState<boolean>(false);
  const [tileHealth, setTileHealth] = useState<'healthy' | 'fallback-active' | 'degraded'>('healthy');

  // Apply basemap with fallback guard
  const applyBasemap = useCallback((mode: BasemapMode, key: string, map: L.Map) => {
    if (currentTileLayerRef.current) {
      map.removeLayer(currentTileLayerRef.current);
      currentTileLayerRef.current = null;
    }

    if (offlineVectorLayerRef.current) {
      offlineVectorLayerRef.current.clearLayers();
    }

    if (mode === 'offline-vector') {
      const vectorGroup = offlineVectorLayerRef.current || L.layerGroup().addTo(map);
      offlineVectorLayerRef.current = vectorGroup;

      const thames = L.polyline(thamesCoordinates, {
        color: '#1A365D',
        weight: 14,
        opacity: 0.8,
        lineCap: 'round',
        lineJoin: 'round',
      });
      vectorGroup.addLayer(thames);

      londonArterials.forEach((coords) => {
        const road = L.polyline(coords, {
          color: '#2A3444',
          weight: 4,
          opacity: 0.7,
        });
        vectorGroup.addLayer(road);
      });

      setTileHealth('healthy');
    } else {
      let tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      let tileClass = 'map-tiles-dark';
      let attribution = '&copy; OpenStreetMap • Keyless Guard Active';

      if (mode === 'custom-key' && key.trim().length > 5) {
        tileUrl = `https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token=${key.trim()}`;
        tileClass = '';
        attribution = '&copy; Mapbox & OpenStreetMap (Enterprise Token)';
      }

      const newTileLayer = L.tileLayer(tileUrl, {
        maxZoom: 19,
        className: tileClass,
        attribution: `<span style="color:#666;font-size:10px;">${attribution}</span>`,
      });

      newTileLayer.on('tileerror', () => {
        console.warn('[RouteOptimizerMap] Tile error intercepted. Engaging Keyless OSM fallback.');
        setTileHealth('fallback-active');
        if (mode === 'custom-key') {
          setBasemapMode('keyless-dark-osm');
        }
      });

      newTileLayer.addTo(map);
      currentTileLayerRef.current = newTileLayer;
    }
  }, []);

  // 1. Initialize Map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (mapInstanceRef.current) {
      mapInstanceRef.current.remove();
    }

    const map = L.map(mapContainerRef.current, {
      center: [51.5160, -0.1050],
      zoom: 13,
      zoomControl: true,
      attributionControl: false,
    });

    offlineVectorLayerRef.current = L.layerGroup().addTo(map);
    routesLayerRef.current = L.layerGroup().addTo(map);
    hazardLayerRef.current = L.layerGroup().addTo(map);

    applyBasemap(basemapMode, apiKey, map);

    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, [applyBasemap, basemapMode, apiKey]);

  // 2. Render Storm Hazard polygon if simStorm
  useEffect(() => {
    const hazardGroup = hazardLayerRef.current;
    if (!hazardGroup) return;

    hazardGroup.clearLayers();

    if (simStorm) {
      const hazardPoly = L.polygon(stormZoneB.coordinates, {
        color: '#FF2E63',
        weight: 2,
        dashArray: '5, 5',
        fillColor: '#FF2E63',
        fillOpacity: 0.15,
      });

      hazardPoly.bindTooltip('Zone B Disruption Zone (Avoided by AI Path)', {
        permanent: true,
        direction: 'center',
        className: 'bg-rose-950/80 text-rose-300 text-[10px] font-bold border border-rose-700',
      });

      hazardGroup.addLayer(hazardPoly);
    }
  }, [simStorm]);

  // 3. Render Routes (Original Baseline vs Executed/Active)
  useEffect(() => {
    const routesGroup = routesLayerRef.current;
    if (!routesGroup) return;

    routesGroup.clearLayers();

    // Baseline route (Red dashed if executed, or red solid if unoptimized)
    const origPoints: [number, number][] = routeOrig.map((p) => [p.lat, p.lng]);
    const origPolyline = L.polyline(origPoints, {
      color: '#FF2E63',
      weight: executed ? 3 : 4,
      dashArray: executed ? '6, 6' : undefined,
      opacity: executed ? 0.6 : 0.9,
    });
    origPolyline.bindPopup(
      `<div style="font-family:'Inter', sans-serif;font-size:11px;">
        <b style="color:#FF2E63;">Original Planned Transit Route</b><br/>
        Traverses Zone B direct corridor (Subject to severe weather disruption)
      </div>`
    );
    routesGroup.addLayer(origPolyline);

    // Optimized route (Cyan/Emerald path when executed)
    if (executed && activeRoute.length > 0) {
      const optPoints: [number, number][] = activeRoute.map((p) => [p.lat, p.lng]);
      const optPolyline = L.polyline(optPoints, {
        color: '#00ADB5',
        weight: 4,
        opacity: 0.95,
      });
      optPolyline.bindPopup(
        `<div style="font-family:'Inter', sans-serif;font-size:11px;">
          <b style="color:#00ADB5;">Active Executed AI Bypass Route</b><br/>
          Circumvents Zone B flash-flood boundary via Holborn arterial corridor.<br/>
          <span>Traction saving: <b>14.2 kWh</b> | Latency: <b>-18 min</b></span>
        </div>`
      );
      routesGroup.addLayer(optPolyline);
    }

    // Origin Marker (Depot B)
    const startCoord = routeOrig[0];
    const startIcon = L.divIcon({
      className: 'route-node-icon',
      html: `
        <div style="
          background:#181B20;
          border:2px solid #00ADB5;
          color:#00ADB5;
          width:22px;
          height:22px;
          border-radius:50%;
          display:flex;
          align-items:center;
          justify-content:center;
          font-weight:bold;
          font-size:10px;
          box-shadow: 0 0 8px #00ADB5;
        ">
          S
        </div>
      `,
      iconSize: [22, 22],
      iconAnchor: [11, 11],
    });
    const startMarker = L.marker([startCoord.lat, startCoord.lng], { icon: startIcon });
    startMarker.bindTooltip('Origin: Depot B Shoreditch', { direction: 'top' });
    routesGroup.addLayer(startMarker);

    // Destination Marker (Westminster Hub)
    const endCoord = routeOrig[routeOrig.length - 1];
    const endIcon = L.divIcon({
      className: 'route-node-icon',
      html: `
        <div style="
          background:#181B20;
          border:2px solid #28a745;
          color:#28a745;
          width:22px;
          height:22px;
          border-radius:50%;
          display:flex;
          align-items:center;
          justify-content:center;
          font-weight:bold;
          font-size:10px;
          box-shadow: 0 0 8px #28a745;
        ">
          D
        </div>
      `,
      iconSize: [22, 22],
      iconAnchor: [11, 11],
    });
    const endMarker = L.marker([endCoord.lat, endCoord.lng], { icon: endIcon });
    endMarker.bindTooltip('Destination: Westminster Hub', { direction: 'top' });
    routesGroup.addLayer(endMarker);
  }, [activeRoute, executed]);

  return (
    <div className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl overflow-hidden shadow-lg flex flex-col">
      {/* Card Header */}
      <div className="px-4 py-3 bg-[#14171C] border-b border-[#242932] flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <Navigation className="w-4 h-4 text-[#00ADB5]" />
          <h3 className="text-sm font-bold text-white uppercase tracking-wider">
            Route Optimizer: Dynamic Transit Trajectory
          </h3>
        </div>

        <div className="flex items-center gap-2">
          {/* Basemap Guard & API Settings Button */}
          <button
            onClick={() => setIsConfigModalOpen(true)}
            title="Configure Map Source & Dependency Guard"
            className="bg-[#181B20] border border-[#00ADB5]/70 hover:border-[#00ADB5] text-white px-2 py-1 rounded text-xs flex items-center gap-1.5 transition-colors cursor-pointer"
          >
            <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
            <span className="hidden sm:inline font-mono-data text-[10px]">Tile Guard</span>
            <Settings className="w-3 h-3 text-[#8C93A0]" />
          </button>

          <span
            className={`px-2.5 py-0.5 rounded-full text-xs font-semibold flex items-center gap-1.5 ${
              executed
                ? 'bg-emerald-950/80 border border-emerald-500 text-emerald-400'
                : 'bg-rose-950/80 border border-[#FF2E63] text-[#FF2E63]'
            }`}
          >
            {executed ? (
              <>
                <CheckCircle className="w-3.5 h-3.5" />
                <span>Active Bypass Dispatched</span>
              </>
            ) : (
              <>
                <AlertCircle className="w-3.5 h-3.5" />
                <span>Pending Transit Reroute</span>
              </>
            )}
          </span>
        </div>
      </div>

      {/* Map Content */}
      <div className="relative w-full h-[420px]">
        <div ref={mapContainerRef} className="w-full h-full" />

        {/* Live Route Metrics Ribbon */}
        <div className="absolute top-3 left-3 z-[1000] bg-[#181B20]/95 backdrop-blur-md border border-[#2A2E35] rounded-lg p-2.5 shadow-xl text-xs space-y-1.5 max-w-[240px]">
          <div className="flex items-center justify-between text-[11px] font-semibold text-white border-b border-[#2A2E35] pb-1">
            <span>Route AI Optimization</span>
            <span className="text-emerald-400 font-mono-data">
              -{metrics.durationSavedMin} min
            </span>
          </div>
          <div className="grid grid-cols-2 gap-x-2 gap-y-1 text-[10px] font-mono-data">
            <span className="text-[#8C93A0]">Duration:</span>
            <span className="text-white text-right">
              {metrics.optimizedDurationMin}m vs {metrics.originalDurationMin}m
            </span>

            <span className="text-[#8C93A0]">Fleet Distance:</span>
            <span className="text-white text-right">
              {metrics.optimizedDistanceKm} km
            </span>

            <span className="text-[#8C93A0]">Traction Energy:</span>
            <span className="text-emerald-400 text-right">
              -{metrics.energySavedKWh} kWh
            </span>

            <span className="text-[#8C93A0]">Storm Infiltration:</span>
            <span className="text-emerald-400 text-right">
              {simStorm ? '0% (Circumvented)' : 'Clear'}
            </span>
          </div>
        </div>

        {/* Map Legend */}
        <div className="absolute bottom-3 right-3 z-[1000] bg-[#181B20]/95 backdrop-blur-md border border-[#2A2E35] px-3 py-2 rounded-md text-[11px] font-mono-data shadow-xl flex flex-col gap-1">
          <div className="flex items-center gap-2">
            <span className="w-4 h-0.5 border-t-2 border-dashed border-[#FF2E63]"></span>
            <span className="text-[#C5CDD9]">Original Baseline Path</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-4 h-1 bg-[#00ADB5] rounded"></span>
            <span className="text-[#00ADB5] font-semibold">Executed AI Route</span>
          </div>
        </div>
      </div>

      {/* Card Footer matching specification */}
      <div className="px-4 py-2.5 bg-[#14171C] border-t border-[#2A2E35] text-[11px] text-[#8C93A0] flex items-center justify-between">
        <span>Red Dashed: Unoptimized Path | Green Solid: Executed Active Route</span>
        <span className="font-mono-data text-[#00ADB5]">
          Telemetry Engine Latency: 12ms
        </span>
      </div>

      {/* Map Configuration Modal */}
      <MapConfigModal
        isOpen={isConfigModalOpen}
        onClose={() => setIsConfigModalOpen(false)}
        currentBasemap={basemapMode}
        onSelectBasemap={(mode) => setBasemapMode(mode)}
        apiKey={apiKey}
        onSaveApiKey={(key) => setApiKey(key)}
        tileHealth={tileHealth}
      />
    </div>
  );
};
