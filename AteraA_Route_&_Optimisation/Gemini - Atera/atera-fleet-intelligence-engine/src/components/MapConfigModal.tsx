import React, { useState } from 'react';
import { 
  X, 
  Map, 
  ShieldCheck, 
  Key, 
  Layers, 
  AlertCircle, 
  CheckCircle2, 
  Globe2, 
  Cpu, 
  RefreshCw 
} from 'lucide-react';

export type BasemapMode = 'keyless-dark-osm' | 'offline-vector' | 'custom-key';

interface MapConfigModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentBasemap: BasemapMode;
  onSelectBasemap: (mode: BasemapMode) => void;
  apiKey: string;
  onSaveApiKey: (key: string) => void;
  tileHealth: 'healthy' | 'fallback-active' | 'degraded';
}

export const MapConfigModal: React.FC<MapConfigModalProps> = ({
  isOpen,
  onClose,
  currentBasemap,
  onSelectBasemap,
  apiKey,
  onSaveApiKey,
  tileHealth,
}) => {
  const [inputKey, setInputKey] = useState(apiKey);
  const [isSaved, setIsSaved] = useState(false);

  if (!isOpen) return null;

  const handleSave = () => {
    onSaveApiKey(inputKey);
    setIsSaved(true);
    setTimeout(() => setIsSaved(false), 2000);
  };

  return (
    <div 
      role="dialog"
      aria-modal="true"
      aria-labelledby="map-config-modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm"
    >
      <div 
        className="bg-[#181B20] border-2 border-[#2A2E35] rounded-2xl w-full max-w-xl shadow-2xl overflow-hidden flex flex-col my-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-6 py-4 border-b-2 border-[#2A2E35] bg-[#14171C] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-[#00ADB5]/20 border border-[#00ADB5]/40 text-[#00ADB5]">
              <Layers className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 id="map-config-modal-title" className="text-base font-bold text-white uppercase tracking-wider">
                  Map Basemap & Tile Guard Settings
                </h2>
                <span className="bg-emerald-950 text-emerald-300 border border-emerald-700 text-[10px] font-mono-data px-1.5 py-0.2 rounded font-bold">
                  GUARD ACTIVE
                </span>
              </div>
              <p className="text-xs text-[#8C93A0]">
                Guards against missing API key watermarks, rate limits, and external tile service outages.
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            aria-label="Close map configuration modal"
            className="p-1.5 rounded-lg bg-[#242932] hover:bg-[#2C323D] text-[#8C93A0] hover:text-white border border-[#393E46] transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-5 text-xs">
          {/* Active Guard Status Banner */}
          <div className="p-3.5 rounded-xl bg-[#121417] border-2 border-emerald-800/60 flex items-center justify-between gap-3">
            <div className="flex items-center gap-2.5 text-[#C5CDD9]">
              <ShieldCheck className="w-5 h-5 text-emerald-400 shrink-0" />
              <div>
                <span className="font-bold text-white block">Third-Party Dependency Shield Enabled</span>
                <span className="text-[11px] text-[#8C93A0]">
                  Tile error handlers intercept 401/403/watermarked responses and fail over automatically.
                </span>
              </div>
            </div>
            <span className="bg-emerald-900/60 text-emerald-300 border border-emerald-600 px-2 py-0.5 rounded text-[10px] font-mono-data font-bold">
              {tileHealth === 'healthy' ? 'TILES 100% HEALTHY' : 'FALLBACK ACTIVE'}
            </span>
          </div>

          {/* Basemap Options */}
          <div className="space-y-3">
            <span className="text-[11px] uppercase font-mono-data text-[#8C93A0] font-bold block">
              Select Resilient Basemap Layer
            </span>

            <div className="grid grid-cols-1 gap-2.5">
              {/* Option 1: Keyless Dark OSM (Recommended) */}
              <button
                type="button"
                onClick={() => onSelectBasemap('keyless-dark-osm')}
                className={`p-3.5 rounded-xl border-2 text-left transition-all flex items-start justify-between gap-3 cursor-pointer ${
                  currentBasemap === 'keyless-dark-osm'
                    ? 'bg-[#1D222A] border-[#00ADB5] shadow-lg shadow-[#00ADB5]/10'
                    : 'bg-[#14171C] border-[#2A2E35] hover:border-[#3E4552]'
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className={`p-2 rounded-lg border mt-0.5 ${
                    currentBasemap === 'keyless-dark-osm'
                      ? 'bg-[#00ADB5]/20 border-[#00ADB5] text-[#00ADB5]'
                      : 'bg-[#1C2026] border-[#2E3540] text-[#8C93A0]'
                  }`}>
                    <Globe2 className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-white text-xs">
                        Keyless Dark OSM (Guarded Default)
                      </span>
                      <span className="bg-emerald-950 text-emerald-400 border border-emerald-700 text-[9px] px-1.5 py-0.2 rounded font-bold">
                        ZERO API KEY REQUIRED
                      </span>
                    </div>
                    <p className="text-[11px] text-[#8C93A0] mt-0.5">
                      Uses open-source OpenStreetMap with custom dark contrast filtering. Zero watermarks, zero rate limits, permanent open-access SLA.
                    </p>
                  </div>
                </div>
                {currentBasemap === 'keyless-dark-osm' && (
                  <CheckCircle2 className="w-4 h-4 text-[#00ADB5] shrink-0 mt-1" />
                )}
              </button>

              {/* Option 2: Offline Resilient Vector Map */}
              <button
                type="button"
                onClick={() => onSelectBasemap('offline-vector')}
                className={`p-3.5 rounded-xl border-2 text-left transition-all flex items-start justify-between gap-3 cursor-pointer ${
                  currentBasemap === 'offline-vector'
                    ? 'bg-[#1D222A] border-[#00ADB5] shadow-lg shadow-[#00ADB5]/10'
                    : 'bg-[#14171C] border-[#2A2E35] hover:border-[#3E4552]'
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className={`p-2 rounded-lg border mt-0.5 ${
                    currentBasemap === 'offline-vector'
                      ? 'bg-[#00ADB5]/20 border-[#00ADB5] text-[#00ADB5]'
                      : 'bg-[#1C2026] border-[#2E3540] text-[#8C93A0]'
                  }`}>
                    <Cpu className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-white text-xs">
                        Offline Resilient Vector Map Layer
                      </span>
                      <span className="bg-blue-950 text-blue-300 border border-blue-800 text-[9px] px-1.5 py-0.2 rounded font-bold">
                        100% OFFLINE SAFE
                      </span>
                    </div>
                    <p className="text-[11px] text-[#8C93A0] mt-0.5">
                      Renders London Thames River, coordinate grids, and arterial bypasses procedurally in SVG. Bypasses internet and tile servers entirely.
                    </p>
                  </div>
                </div>
                {currentBasemap === 'offline-vector' && (
                  <CheckCircle2 className="w-4 h-4 text-[#00ADB5] shrink-0 mt-1" />
                )}
              </button>

              {/* Option 3: Custom CartoDB / Mapbox API Key */}
              <button
                type="button"
                onClick={() => onSelectBasemap('custom-key')}
                className={`p-3.5 rounded-xl border-2 text-left transition-all flex items-start justify-between gap-3 cursor-pointer ${
                  currentBasemap === 'custom-key'
                    ? 'bg-[#1D222A] border-[#00ADB5] shadow-lg shadow-[#00ADB5]/10'
                    : 'bg-[#14171C] border-[#2A2E35] hover:border-[#3E4552]'
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className={`p-2 rounded-lg border mt-0.5 ${
                    currentBasemap === 'custom-key'
                      ? 'bg-[#00ADB5]/20 border-[#00ADB5] text-[#00ADB5]'
                      : 'bg-[#1C2026] border-[#2E3540] text-[#8C93A0]'
                  }`}>
                    <Key className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-white text-xs">
                        Enterprise Custom API Key (Carto / Mapbox / Stadia)
                      </span>
                    </div>
                    <p className="text-[11px] text-[#8C93A0] mt-0.5">
                      Supply a licensed enterprise token. If invalid, the automated guard fails back to Keyless Dark OSM automatically.
                    </p>
                  </div>
                </div>
                {currentBasemap === 'custom-key' && (
                  <CheckCircle2 className="w-4 h-4 text-[#00ADB5] shrink-0 mt-1" />
                )}
              </button>
            </div>
          </div>

          {/* API Key Input Dialog (Only shown when custom-key selected or for configuring) */}
          {currentBasemap === 'custom-key' && (
            <div className="p-4 rounded-xl bg-[#121417] border border-[#2A2E35] space-y-2">
              <label htmlFor="input-map-api-key" className="text-[11px] font-bold text-white flex items-center justify-between">
                <span>Enter Mapbox / CartoDB API Key / Access Token:</span>
                {isSaved && <span className="text-emerald-400 font-normal">✓ Token Saved</span>}
              </label>
              <div className="flex gap-2">
                <input
                  id="input-map-api-key"
                  type="password"
                  value={inputKey}
                  onChange={(e) => setInputKey(e.target.value)}
                  placeholder="e.g. pk.eyJ1IjoiYXRlcmEtZmxlZXQi..."
                  className="flex-1 bg-[#1A1D24] border border-[#3A404D] rounded-lg px-3 py-2 text-white font-mono-data text-xs focus:outline-none focus:border-[#00ADB5]"
                />
                <button
                  type="button"
                  onClick={handleSave}
                  className="bg-[#00ADB5] hover:bg-[#008C93] text-[#121417] font-bold px-4 py-2 rounded-lg transition-colors cursor-pointer"
                >
                  Save Key
                </button>
              </div>
              <p className="text-[10px] text-[#8C93A0]">
                If left empty or invalid, the system automatically engages the Keyless Dark OSM basemap to prevent watermark corruption.
              </p>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-3 border-t-2 border-[#2A2E35] bg-[#14171C] flex items-center justify-between text-xs text-[#8C93A0]">
          <span>Protection SLA: Resilient failover within 100ms of tile error</span>
          <button
            onClick={onClose}
            className="bg-[#242932] hover:bg-[#2C323D] text-white px-4 py-1.5 rounded-lg border border-[#3A404D] font-medium"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  );
};
