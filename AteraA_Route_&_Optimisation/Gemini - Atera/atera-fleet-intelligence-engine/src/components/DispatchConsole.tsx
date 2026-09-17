import React from 'react';
import { 
  AlertOctagon, 
  CloudLightning, 
  Zap, 
  Play, 
  CheckCircle2, 
  AlertTriangle, 
  RotateCcw,
  Layers,
  Sparkles,
  Database,
  Trash2,
  ShieldCheck
} from 'lucide-react';

interface DispatchConsoleProps {
  simStorm: boolean;
  onToggleStorm: (val: boolean) => void;
  gridPriceSurge: number;
  onChangeGridPrice: (val: number) => void;
  onExecuteReroute: () => void;
  onResetSimulation: () => void;
  executed: boolean;
  executedAt: string | null;
  statusMsg: string;
  showTraffic: boolean;
  onToggleTraffic: (val: boolean) => void;
  showWeatherOverlay: boolean;
  onToggleWeatherOverlay: (val: boolean) => void;
  onOpenDataLineage?: () => void;
  onOpenDeleteAccount?: () => void;
}

export const DispatchConsole: React.FC<DispatchConsoleProps> = ({
  simStorm,
  onToggleStorm,
  gridPriceSurge,
  onChangeGridPrice,
  onExecuteReroute,
  onResetSimulation,
  executed,
  executedAt,
  statusMsg,
  showTraffic,
  onToggleTraffic,
  showWeatherOverlay,
  onToggleWeatherOverlay,
  onOpenDataLineage,
  onOpenDeleteAccount,
}) => {
  const handleSliderKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowRight' || e.key === 'ArrowUp') {
      e.preventDefault();
      onChangeGridPrice(Math.min(0.60, Number((gridPriceSurge + 0.02).toFixed(2))));
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowDown') {
      e.preventDefault();
      onChangeGridPrice(Math.max(0.10, Number((gridPriceSurge - 0.02).toFixed(2))));
    } else if (e.key === 'Home') {
      e.preventDefault();
      onChangeGridPrice(0.10);
    } else if (e.key === 'End') {
      e.preventDefault();
      onChangeGridPrice(0.60);
    }
  };

  return (
    <aside 
      className="w-full lg:w-80 shrink-0 bg-[#181B20] border-2 border-[#2A2E35] rounded-xl p-4 flex flex-col gap-4 shadow-xl"
      aria-label="Dispatch Control Console"
    >
      {/* Console Header */}
      <div className="flex items-center justify-between border-b-2 border-[#2A2E35] pb-3">
        <div className="flex items-center gap-2">
          <div className="p-1.5 rounded-lg bg-[#242932] text-[#00ADB5] border border-[#2E3540]">
            <AlertOctagon className="w-4 h-4" />
          </div>
          <div>
            <h2 className="text-sm font-bold text-white tracking-wide uppercase">
              Dispatch Console
            </h2>
            <p className="text-[10px] text-[#8C93A0]">Real-Time Scenario Orchestrator</p>
          </div>
        </div>
        <div className="flex items-center gap-1">
          <button
            id="btn-reset-simulation"
            onClick={onResetSimulation}
            title="Reset baseline telemetry"
            aria-label="Reset simulation to baseline"
            className="p-1.5 text-[#8C93A0] hover:text-white hover:bg-[#242932] rounded-lg transition-colors border border-[#2E3540] focus-visible:ring-2 focus-visible:ring-[#00ADB5]"
          >
            <RotateCcw className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Control 1: Simulate Storm Alert (with Met Office Data Lineage Citation) */}
      <div className="space-y-2 bg-[#121417] p-3 rounded-xl border-2 border-[#242830]">
        <div className="flex items-center justify-between">
          <span className="text-[9px] font-mono-data text-[#8C93A0] flex items-center gap-1 bg-[#181B20] px-1.5 py-0.5 rounded border border-[#2E3540]">
            <Database className="w-2.5 h-2.5 text-[#00ADB5]" />
            <span>Source: Met Office UK Doppler</span>
          </span>
          {onOpenDataLineage && (
            <button
              onClick={onOpenDataLineage}
              className="text-[9px] text-[#00ADB5] hover:underline"
            >
              Provenance &rarr;
            </button>
          )}
        </div>

        <label
          htmlFor="sim_storm"
          className="flex items-start justify-between cursor-pointer group pt-1"
        >
          <div className="space-y-0.5 pr-2">
            <div className="flex items-center gap-1.5">
              <CloudLightning
                className={`w-4 h-4 transition-colors ${
                  simStorm ? 'text-amber-400' : 'text-[#6B7280]'
                }`}
              />
              <span className="text-xs font-bold text-white group-hover:text-[#00ADB5] transition-colors">
                Simulate Storm Alert (Zone B)
              </span>
            </div>
            <p className="text-[11px] text-[#8C93A0] leading-snug">
              Triggers flash flooding & hazard gridlock in Old St / Islington corridor
            </p>
          </div>
          <input
            type="checkbox"
            id="sim_storm"
            checked={simStorm}
            onChange={(e) => onToggleStorm(e.target.checked)}
            aria-label="Simulate Storm Alert in Zone B"
            className="mt-1 h-5 w-5 rounded bg-[#242932] border-2 border-[#393E46] text-[#00ADB5] focus:ring-[#00ADB5] focus:ring-offset-0 cursor-pointer accent-[#00ADB5]"
          />
        </label>

        {simStorm && (
          <div className="pt-2 border-t border-[#1E232B] flex items-center justify-between text-[11px]">
            <span className="text-amber-400 font-mono-data font-semibold flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-amber-400 animate-ping"></span>
              VAN-102 Impeded (Delayed)
            </span>
            <span className="text-[#8C93A0] font-mono-data">Zone B Active</span>
          </div>
        )}
      </div>

      {/* Control 2: Depot Electricity Rate Slider (with National Grid ESO Lineage Citation) */}
      <div className="space-y-2 bg-[#121417] p-3 rounded-xl border-2 border-[#242830]">
        <div className="flex items-center justify-between">
          <span className="text-[9px] font-mono-data text-[#8C93A0] flex items-center gap-1 bg-[#181B20] px-1.5 py-0.5 rounded border border-[#2E3540]">
            <Database className="w-2.5 h-2.5 text-[#00ADB5]" />
            <span>Source: National Grid ESO Live API v3.2</span>
          </span>
          <span className="font-mono-data text-xs font-bold text-[#00ADB5] bg-[#00ADB5]/15 px-2 py-0.5 rounded border border-[#00ADB5]/30">
            ${gridPriceSurge.toFixed(2)}/kWh
          </span>
        </div>

        <div className="flex items-center justify-between pt-1">
          <label
            htmlFor="grid_price_surge"
            className="flex items-center gap-1.5 text-xs font-bold text-white"
          >
            <Zap className="w-3.5 h-3.5 text-[#00ADB5]" />
            <span>Depot Grid Tariff Rate:</span>
          </label>
        </div>

        <input
          type="range"
          id="grid_price_surge"
          min="0.10"
          max="0.60"
          step="0.02"
          value={gridPriceSurge}
          onChange={(e) => onChangeGridPrice(parseFloat(e.target.value))}
          onKeyDown={handleSliderKeyDown}
          aria-label="Depot Electricity Rate ($/kWh)"
          aria-valuenow={gridPriceSurge}
          aria-valuemin={0.10}
          aria-valuemax={0.60}
          className="w-full h-2 bg-[#242932] rounded-lg appearance-none cursor-pointer accent-[#00ADB5] focus:outline-none focus:ring-2 focus:ring-[#00ADB5]"
        />

        <div className="flex justify-between text-[10px] text-[#6B7280] font-mono-data">
          <span>Off-peak: $0.10</span>
          <span>Baseline: $0.18</span>
          <span>Peak Surge: $0.60</span>
        </div>

        {gridPriceSurge > 0.30 && (
          <div className="mt-1 text-[11px] text-amber-300 bg-amber-950/40 p-2 rounded-lg border border-amber-800 flex items-center gap-1.5">
            <AlertTriangle className="w-3.5 h-3.5 text-amber-400 shrink-0" />
            <span>High grid tariff! AI rescheduling will shift load to 00:00-04:00.</span>
          </div>
        )}
      </div>

      {/* Map Overlays Toggle (with TfL UTC Lineage) */}
      <div className="bg-[#121417] p-3 rounded-xl border-2 border-[#242830] space-y-2">
        <div className="flex items-center justify-between text-xs font-medium text-[#8C93A0] pb-1 border-b border-[#1E232B]">
          <div className="flex items-center gap-1.5">
            <Layers className="w-3.5 h-3.5" />
            <span className="font-bold text-white text-[11px]">GIS Live Feeds</span>
          </div>
          <span className="text-[9px] font-mono-data text-[#8C93A0]">TfL UTC & Met</span>
        </div>
        <div className="grid grid-cols-2 gap-2 text-xs">
          <button
            id="toggle-traffic-overlay"
            onClick={() => onToggleTraffic(!showTraffic)}
            aria-pressed={showTraffic}
            aria-label="Toggle Congestion GIS layer"
            className={`min-h-[40px] px-2.5 py-1.5 rounded-lg text-left flex items-center justify-between border-2 transition-all cursor-pointer ${
              showTraffic
                ? 'bg-[#242932] text-white border-[#00ADB5]'
                : 'bg-[#181B20] text-[#6B7280] border-[#242830]'
            }`}
          >
            <span className="text-[11px] font-semibold">TfL Traffic</span>
            <span
              className={`w-2 h-2 rounded-full ${
                showTraffic ? 'bg-amber-400' : 'bg-gray-600'
              }`}
            ></span>
          </button>

          <button
            id="toggle-weather-overlay"
            onClick={() => onToggleWeatherOverlay(!showWeatherOverlay)}
            aria-pressed={showWeatherOverlay}
            aria-label="Toggle Weather Radar layer"
            className={`min-h-[40px] px-2.5 py-1.5 rounded-lg text-left flex items-center justify-between border-2 transition-all cursor-pointer ${
              showWeatherOverlay
                ? 'bg-[#242932] text-white border-[#00ADB5]'
                : 'bg-[#181B20] text-[#6B7280] border-[#242830]'
            }`}
          >
            <span className="text-[11px] font-semibold">Radar Cloud</span>
            <span
              className={`w-2 h-2 rounded-full ${
                showWeatherOverlay ? 'bg-[#00ADB5]' : 'bg-gray-600'
              }`}
            ></span>
          </button>
        </div>
      </div>

      {/* Action Button: Execute Reroute Queue (High Contrast & 44px+ touch target) */}
      <div className="pt-1">
        <button
          id="trigger_reroute"
          onClick={onExecuteReroute}
          aria-label="Execute Fleet Reroute Queue and Automated Charging Optimization"
          className="w-full min-h-[46px] bg-[#00ADB5] hover:bg-[#009299] active:scale-[0.98] text-[#121417] font-extrabold text-xs uppercase tracking-wider py-3 px-4 rounded-xl flex items-center justify-center gap-2 shadow-lg shadow-[#00ADB5]/20 border-2 border-[#00ADB5] transition-all cursor-pointer focus-visible:ring-2 focus-visible:ring-white"
        >
          <Play className="w-4 h-4 fill-current" />
          <span>Execute Reroute Queue</span>
        </button>
      </div>

      {/* Execution Status Banner (exact specification) */}
      <div
        id="execution_status_banner"
        role="status"
        aria-live="polite"
        className={`p-3 rounded-xl border-2 text-xs leading-relaxed transition-all ${
          executed
            ? 'bg-emerald-950/60 text-emerald-300 border-emerald-600'
            : 'bg-[#242932]/80 text-[#9CA3AF] border-[#2E3540]'
        }`}
      >
        <div className="flex items-start gap-2">
          {executed ? (
            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
          ) : (
            <Sparkles className="w-4 h-4 text-[#00ADB5] shrink-0 mt-0.5" />
          )}
          <div>
            <div className="font-bold text-white">
              {executed ? 'Dispatch Queue Executed' : 'Standby Mode'}
            </div>
            <div className="mt-0.5 font-mono-data text-[11px] break-words">
              {statusMsg}
            </div>
            {executed && executedAt && (
              <div className="mt-1 text-[10px] text-emerald-400 font-mono-data font-semibold">
                Broadcast timestamp: {executedAt}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Prominent 1-Click Delete Account & Wipe in Console (Constraint 1: Regulation) */}
      {onOpenDeleteAccount && (
        <div className="pt-2 border-t border-[#2A2E35]">
          <button
            onClick={onOpenDeleteAccount}
            aria-label="1-Click Delete Account and Wipe Telemetry Data"
            className="w-full py-2 px-3 bg-[#FF2E63]/15 hover:bg-[#FF2E63] text-[#FF2E63] hover:text-white border-2 border-[#FF2E63]/60 rounded-lg text-[11px] font-bold uppercase tracking-wider flex items-center justify-center gap-2 transition-all cursor-pointer"
          >
            <Trash2 className="w-3.5 h-3.5" />
            <span>1-Click Delete Account & Wipe</span>
          </button>
          <span className="text-[9px] text-[#8C93A0] block text-center mt-1 font-mono-data">
            Complies with GDPR Art. 17 & CCPA Right to Erasure
          </span>
        </div>
      )}
    </aside>
  );
};
