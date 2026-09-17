import React, { useEffect, useRef, useState, useCallback } from 'react';
import L from 'leaflet';
import { VehicleTelemetry } from '../types';
import { stormZoneB, trafficCongestionSegments, depotB } from '../data/fleetData';
import { Maximize2, ShieldCheck, Layers, Settings, AlertTriangle, Globe2, RefreshCw } from 'lucide-react';
import { MapConfigModal, BasemapMode } from './MapConfigModal';

interface DispatchMapProps {
  fleet: VehicleTelemetry[];
  simStorm: boolean;
  executed: boolean;
  selectedVehicleId: string | null;
  onSelectVehicle: (id: string) => void;
  showTraffic: boolean;
  showWeatherOverlay: boolean;
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

// Major London Arterials for offline vector rendering
const londonArterials: [number, number][][] = [
  [[51.5140, -0.1600], [51.5160, -0.1300], [51.5170, -0.1000], [51.5190, -0.0600]],
  [[51.5250, -0.1190], [51.5170, -0.1190], [51.5060, -0.1170], [51.4980, -0.1100]],
  [[51.5320, -0.1050], [51.5260, -0.0920], [51.5190, -0.0860]],
  [[51.5030, -0.1180], [51.4980, -0.0950], [51.5050, -0.0700]],
];

export const DispatchMap: React.FC<DispatchMapProps> = ({
  fleet,
  simStorm,
  executed,
  selectedVehicleId,
  onSelectVehicle,
  showTraffic,
  showWeatherOverlay,
}) => {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const currentTileLayerRef = useRef<L.TileLayer | null>(null);
  const offlineVectorLayerRef = useRef<L.LayerGroup | null>(null);
  const markersLayerRef = useRef<L.LayerGroup | null>(null);
  const weatherLayerRef = useRef<L.LayerGroup | null>(null);
  const trafficLayerRef = useRef<L.LayerGroup | null>(null);
  const depotLayerRef = useRef<L.LayerGroup | null>(null);

  // Basemap Guard State
  const [basemapMode, setBasemapMode] = useState<BasemapMode>('keyless-dark-osm');
  const [apiKey, setApiKey] = useState<string>('');
  const [isConfigModalOpen, setIsConfigModalOpen] = useState<boolean>(false);
  const [tileHealth, setTileHealth] = useState<'healthy' | 'fallback-active' | 'degraded'>('healthy');
  const [fallbackWarning, setFallbackWarning] = useState<string | null>(null);

  // Helper to determine vehicle color strictly matching the specification
  const getVehicleColor = (status: string): string => {
    if (status === 'Charging Depot B') {
      return '#00ADB5'; // Cyan
    }
    if (status.includes('Delayed') || status.includes('STRANDED')) {
      return '#FF2E63'; // Alert Red
    }
    if (status.includes('REROUTED') || status.includes('OPTIMIZED')) {
      return '#28a745'; // Emerald/Green
    }
    return '#F39C12'; // Amber/On Route
  };

  // Switch or mount the basemap layer with active fallback guards
  const applyBasemap = useCallback((mode: BasemapMode, key: string, map: L.Map) => {
    // 1. Remove existing tile layer if present
    if (currentTileLayerRef.current) {
      map.removeLayer(currentTileLayerRef.current);
      currentTileLayerRef.current = null;
    }

    // 2. Clear offline vector basemap
    if (offlineVectorLayerRef.current) {
      offlineVectorLayerRef.current.clearLayers();
    }

    if (mode === 'offline-vector') {
      // Procedural Vector Basemap (Zero External Requests)
      const vectorGroup = offlineVectorLayerRef.current || L.layerGroup().addTo(map);
      offlineVectorLayerRef.current = vectorGroup;

      // River Thames
      const thames = L.polyline(thamesCoordinates, {
        color: '#1A365D',
        weight: 16,
        opacity: 0.8,
        lineCap: 'round',
        lineJoin: 'round',
      });
      thames.bindTooltip('River Thames (Offline Vector Nav Baseline)', {
        direction: 'center',
        className: 'bg-[#0F172A] text-blue-300 text-[9px] border border-blue-900',
      });
      vectorGroup.addLayer(thames);

      // Arterial Roads
      londonArterials.forEach((coords) => {
        const road = L.polyline(coords, {
          color: '#2A3444',
          weight: 4,
          opacity: 0.7,
        });
        vectorGroup.addLayer(road);
      });

      // City Center Landmark Marker
      const centerMarker = L.circleMarker([51.5074, -0.1278], {
        radius: 4,
        color: '#64748B',
        fillColor: '#334155',
        fillOpacity: 1,
      }).bindTooltip('Central London Hub (Charing Cross)', { direction: 'top' });
      vectorGroup.addLayer(centerMarker);

      setTileHealth('healthy');
      setFallbackWarning(null);
    } else {
      // Tile Layer Setup (Keyless Dark OSM or Custom Enterprise Key)
      let tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      let tileClass = 'map-tiles-dark';
      let attribution = '&copy; OpenStreetMap contributors • Keyless Tile Guard Active';

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

      // ACTIVE GUARD: Intercept 401/403/Watermarked tile errors and fail over safely
      newTileLayer.on('tileerror', () => {
        if (tileHealth !== 'fallback-active') {
          console.warn('[MapBasemapGuard] External tile failed. Triggering automated fallback to Keyless Dark OSM.');
          setTileHealth('fallback-active');
          setFallbackWarning('External tile service failed or watermarked. Fallback guard automatically engaged Keyless Dark OSM.');
          
          // Switch to keyless OSM if custom key failed
          if (mode === 'custom-key') {
            setBasemapMode('keyless-dark-osm');
          }
        }
      });

      newTileLayer.addTo(map);
      currentTileLayerRef.current = newTileLayer;
    }
  }, [tileHealth]);

  // 1. Initialize Map once
  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (mapInstanceRef.current) {
      mapInstanceRef.current.remove();
    }

    const map = L.map(mapContainerRef.current, {
      center: [51.5120, -0.1150],
      zoom: 13,
      zoomControl: true,
      attributionControl: false,
    });

    offlineVectorLayerRef.current = L.layerGroup().addTo(map);
    markersLayerRef.current = L.layerGroup().addTo(map);
    weatherLayerRef.current = L.layerGroup().addTo(map);
    trafficLayerRef.current = L.layerGroup().addTo(map);
    depotLayerRef.current = L.layerGroup().addTo(map);

    // Apply basemap with fallback guard
    applyBasemap(basemapMode, apiKey, map);

    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, [applyBasemap, basemapMode, apiKey]);

  // 2. Render Depot B
  useEffect(() => {
    const map = mapInstanceRef.current;
    const depotGroup = depotLayerRef.current;
    if (!map || !depotGroup) return;

    depotGroup.clearLayers();

    const depotIcon = L.divIcon({
      className: 'custom-depot-marker',
      html: `
        <div style="
          background: #181B20;
          border: 2px solid #00ADB5;
          color: #00ADB5;
          width: 32px;
          height: 32px;
          border-radius: 6px;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 0 12px rgba(0, 173, 181, 0.4);
          font-weight: bold;
          font-size: 11px;
          cursor: pointer;
        ">
          ⚡B
        </div>
      `,
      iconSize: [32, 32],
      iconAnchor: [16, 16],
    });

    const marker = L.marker([depotB.lat, depotB.lng], { icon: depotIcon });
    marker.bindPopup(`
      <div style="font-family: 'Inter', sans-serif;">
        <div style="display:flex;align-items:center;gap:6px;margin-bottom:6px;">
          <span style="background:#00ADB5;color:#121417;font-weight:bold;font-size:10px;padding:2px 6px;border-radius:4px;">DEPOT B</span>
          <b style="color:#fff;font-size:13px;">${depotB.name}</b>
        </div>
        <div style="font-size:11px;color:#9CA3AF;line-height:1.6;font-family:'JetBrains Mono',monospace;">
          <div>Active Fleet Chargers: <span style="color:#00ADB5;font-weight:bold;">${depotB.chargersInUse} / ${depotB.chargersTotal} Active</span></div>
          <div>Current Depot Draw: <span style="color:#fff;">${depotB.currentDrawKw} kW / ${depotB.maxCapacityKw} kW max</span></div>
          <div>Substation Guard: <span style="color:#34D399;font-weight:bold;">Breaker Clamped at 600 kW</span></div>
        </div>
      </div>
    `);
    depotGroup.addLayer(marker);
  }, []);

  // 3. Render Weather Overlay (Zone B Storm Alert)
  useEffect(() => {
    const map = mapInstanceRef.current;
    const weatherGroup = weatherLayerRef.current;
    if (!map || !weatherGroup) return;

    weatherGroup.clearLayers();

    if (simStorm && showWeatherOverlay) {
      const stormPolygon = L.polygon(stormZoneB.coordinates, {
        color: '#FF2E63',
        weight: 2,
        dashArray: '6, 6',
        fillColor: '#FF2E63',
        fillOpacity: 0.18,
        className: 'pulse-hazard',
      });

      stormPolygon.bindPopup(`
        <div style="font-family:'Inter', sans-serif; min-width: 220px;">
          <div style="display:flex;align-items:center;gap:6px;margin-bottom:6px;">
            <span style="background:#FF2E63;color:#fff;font-weight:bold;font-size:10px;padding:2px 6px;border-radius:4px;">FLASH FLOOD ALERT</span>
            <b style="color:#FF2E63;font-size:12px;">Met Office Radar</b>
          </div>
          <div style="font-size:11px;color:#CBD5E1;line-height:1.5;">
            <b>Zone B (Old St / Shoreditch)</b><br/>
            Heavy precipitation: 45mm/hr. Standing surface water on A501 arterial.<br/>
            <span style="color:#F87171;font-weight:600;">Status: Severe Transit Delay Warning</span>
          </div>
        </div>
      `);

      weatherGroup.addLayer(stormPolygon);

      const stormCenter = L.circleMarker([51.5200, -0.0900], {
        radius: 6,
        color: '#FF2E63',
        fillColor: '#FF2E63',
        fillOpacity: 0.9,
      });
      stormCenter.bindTooltip('Zone B Storm Epicenter', { permanent: true, direction: 'top' });
      weatherGroup.addLayer(stormCenter);
    }
  }, [simStorm, showWeatherOverlay]);

  // 4. Render Live Congestion Segments
  useEffect(() => {
    const map = mapInstanceRef.current;
    const trafficGroup = trafficLayerRef.current;
    if (!map || !trafficGroup) return;

    trafficGroup.clearLayers();

    if (showTraffic) {
      trafficCongestionSegments.forEach((segment) => {
        const poly = L.polyline(segment.coords, {
          color: segment.level === 'severe' ? '#FF2E63' : '#F39C12',
          weight: 5,
          opacity: 0.8,
          lineCap: 'round',
        });

        poly.bindPopup(`
          <div style="font-family:'Inter', sans-serif;font-size:11px;">
            <b style="color:#fff;">${segment.name}</b><br/>
            <span>Traffic Speed: <b>${segment.speedMph} mph</b></span><br/>
            <span style="color:${segment.level === 'severe' ? '#FF2E63' : '#F39C12'};font-weight:bold;">
              Congestion Level: ${segment.level.toUpperCase()}
            </span>
          </div>
        `);

        trafficGroup.addLayer(poly);
      });
    }
  }, [showTraffic]);

  // 5. Render Vehicle Markers
  useEffect(() => {
    const map = mapInstanceRef.current;
    const markersGroup = markersLayerRef.current;
    if (!map || !markersGroup) return;

    markersGroup.clearLayers();

    fleet.forEach((vehicle) => {
      const isSelected = selectedVehicleId === vehicle.vehicle_id;
      const color = getVehicleColor(vehicle.status);

      const markerHtml = `
        <div style="
          position: relative;
          display: flex;
          align-items: center;
          justify-content: center;
          width: 34px;
          height: 34px;
          cursor: pointer;
        ">
          ${
            isSelected
              ? `<div style="
                  position: absolute;
                  width: 44px;
                  height: 44px;
                  border-radius: 50%;
                  border: 2px dashed ${color};
                  animation: spin 6s linear infinite;
                "></div>`
              : ''
          }
          <div style="
            background: #181B20;
            border: 2px solid ${color};
            color: ${color};
            width: 28px;
            height: 28px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 10px;
            font-weight: bold;
            font-family: 'JetBrains Mono', monospace;
            box-shadow: 0 0 10px ${color}88;
          ">
            ${vehicle.type === 'Last-Mile EV' ? 'EV' : 'FR'}
          </div>
          <div style="
            position: absolute;
            bottom: -16px;
            background: #121417;
            border: 1px solid #2A2E35;
            color: #E0E0E0;
            font-size: 9px;
            font-family: 'JetBrains Mono', monospace;
            padding: 1px 4px;
            border-radius: 3px;
            white-space: nowrap;
            font-weight: 600;
          ">
            ${vehicle.vehicle_id}
          </div>
        </div>
      `;

      const customIcon = L.divIcon({
        className: 'vehicle-marker',
        html: markerHtml,
        iconSize: [34, 34],
        iconAnchor: [17, 17],
      });

      const marker = L.marker([vehicle.lat, vehicle.lng], { icon: customIcon });

      marker.bindPopup(`
        <div style="font-family:'Inter', sans-serif;min-width:190px;">
          <div style="display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid #2A2E35;padding-bottom:5px;margin-bottom:6px;">
            <b style="color:#fff;font-size:13px;font-family:'JetBrains Mono',monospace;">${vehicle.vehicle_id}</b>
            <span style="font-size:10px;color:#9CA3AF;background:#242932;padding:1px 5px;border-radius:3px;">${vehicle.type}</span>
          </div>
          <div style="font-size:11px;color:#CBD5E1;line-height:1.6;">
            <div><b>Status:</b> <span style="color:${color};font-weight:600;">${vehicle.status}</span></div>
            <div><b>Battery:</b> <span style="font-family:'JetBrains Mono',monospace;color:#00ADB5;">${vehicle.battery_pct}%</span></div>
            <div><b>Driver Hours Left:</b> <span style="font-family:'JetBrains Mono',monospace;color:#fff;">${vehicle.driver_hours_left} hrs</span></div>
            <div><b>Driver:</b> ${vehicle.driver_name}</div>
            <div><b>Destination:</b> ${vehicle.destination}</div>
          </div>
        </div>
      `);

      marker.on('click', () => {
        onSelectVehicle(vehicle.vehicle_id);
      });

      markersGroup.addLayer(marker);
    });
  }, [fleet, selectedVehicleId, onSelectVehicle]);

  // Center map on selected vehicle if changed
  useEffect(() => {
    if (!selectedVehicleId || !mapInstanceRef.current) return;
    const target = fleet.find((v) => v.vehicle_id === selectedVehicleId);
    if (target) {
      mapInstanceRef.current.panTo([target.lat, target.lng], { animate: true, duration: 0.8 });
    }
  }, [selectedVehicleId, fleet]);

  const handleRecenter = () => {
    if (mapInstanceRef.current) {
      mapInstanceRef.current.setView([51.5120, -0.1150], 13);
    }
  };

  const getBasemapLabel = () => {
    switch (basemapMode) {
      case 'keyless-dark-osm':
        return 'Keyless Dark OSM (Guarded)';
      case 'offline-vector':
        return 'Offline Resilient Vector';
      case 'custom-key':
        return 'Enterprise Token';
    }
  };

  return (
    <div className="relative w-full h-[520px] rounded-xl overflow-hidden border-2 border-[#2A2E35] bg-[#121417]">
      {/* Map Container */}
      <div ref={mapContainerRef} className="w-full h-full" />

      {/* Map Header Overlay with Tile Guard indicator */}
      <div className="absolute top-3 left-3 z-[1000] bg-[#181B20]/95 backdrop-blur-sm border-2 border-[#2A2E35] px-3 py-1.5 rounded-md flex flex-wrap items-center gap-2 text-xs shadow-md">
        <span className="w-2 h-2 rounded-full bg-[#00ADB5] animate-ping"></span>
        <span className="font-semibold text-white">Live Telemetry & GIS Weather Overlay</span>
        <span className="text-[#8C93A0] font-mono-data text-[10px] hidden sm:inline">
          Basemap: {getBasemapLabel()}
        </span>
      </div>

      {/* Map Quick Controls + Guard Settings */}
      <div className="absolute top-3 right-3 z-[1000] flex items-center gap-2">
        {/* Basemap Guard & API Settings Button */}
        <button
          onClick={() => setIsConfigModalOpen(true)}
          title="Configure Map Source & Third-Party Dependency Guard"
          className="bg-[#181B20]/95 backdrop-blur-sm border-2 border-[#00ADB5]/70 hover:border-[#00ADB5] text-white px-2.5 py-1.5 rounded-md text-xs flex items-center gap-1.5 hover:bg-[#242932] transition-colors shadow-md cursor-pointer"
        >
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
          <span className="hidden sm:inline font-bold">Basemap Guard</span>
          <Settings className="w-3 h-3 text-[#8C93A0]" />
        </button>

        <button
          onClick={handleRecenter}
          title="Recenter Central London View"
          className="bg-[#181B20]/90 backdrop-blur-sm border border-[#2A2E35] text-[#9CA3AF] hover:text-white px-2.5 py-1.5 rounded-md text-xs flex items-center gap-1.5 hover:bg-[#242932] transition-colors shadow-md cursor-pointer"
        >
          <Maximize2 className="w-3.5 h-3.5" />
          <span>Reset</span>
        </button>
      </div>

      {/* Non-intrusive fallback active alert if triggered */}
      {fallbackWarning && (
        <div className="absolute top-12 left-3 right-3 z-[1000] bg-amber-950/90 border-2 border-amber-600 px-3 py-2 rounded-lg text-amber-200 text-xs flex items-center justify-between shadow-xl">
          <div className="flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 text-amber-400 shrink-0" />
            <span>{fallbackWarning}</span>
          </div>
          <button
            onClick={() => setFallbackWarning(null)}
            className="text-amber-400 hover:text-white font-bold ml-2 text-xs"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Map Legend (Screen 1) */}
      <div className="absolute bottom-3 left-3 z-[1000] bg-[#181B20]/90 backdrop-blur-sm border border-[#2A2E35] px-3 py-2 rounded-md text-[11px] shadow-lg flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-[#00ADB5]"></span>
          <span className="text-[#C5CDD9]">Depot Charging</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-[#F39C12]"></span>
          <span className="text-[#C5CDD9]">On Route</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-[#FF2E63]"></span>
          <span className="text-[#C5CDD9]">Delayed / Stranded</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-[#28a745]"></span>
          <span className="text-[#C5CDD9]">Rerouted / Optimized</span>
        </div>
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
