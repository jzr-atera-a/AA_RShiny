import React from 'react';
import { Truck, CloudRain, Bolt, DollarSign, Clock, ShieldCheck, Database } from 'lucide-react';
import { VehicleTelemetry } from '../types';

interface KpiBarProps {
  fleet: VehicleTelemetry[];
  simStorm: boolean;
  executed: boolean;
  gridPriceSurge: number;
  onOpenDataLineage?: () => void;
}

export const KpiBar: React.FC<KpiBarProps> = ({
  fleet,
  simStorm,
  executed,
  gridPriceSurge,
  onOpenDataLineage,
}) => {
  // Disruption status logic with truth-in-telemetry guard:
  // If an asset is stalled at 0 mph inside the hazard zone, rerouting cannot magically mitigate it;
  // the system flags that recovery dispatch is required rather than claiming 100% resolution.
  const hasStrandedAsset = fleet.some(
    (v) => v.speed_mph === 0 && (v.status.includes('STRANDED') || v.status.includes('Waterlogged'))
  );

  const disruptionStatus = hasStrandedAsset
    ? '1 Stranded (Tow Req)'
    : simStorm && !executed
    ? '1 Hazard Alert'
    : simStorm && executed
    ? 'Mitigated (Rerouted)'
    : 'Nominal';

  // Average battery calculation
  const avgBattery = Math.round(
    fleet.reduce((acc, v) => acc + v.battery_pct, 0) / (fleet.length || 1)
  );

  // Total driver hours left in pool
  const totalDriverHours = fleet
    .reduce((acc, v) => acc + v.driver_hours_left, 0)
    .toFixed(1);

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 w-full">
      {/* KPI 1: Active Fleet */}
      <div
        id="kpi-active-fleet"
        className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl p-3.5 flex flex-col justify-between shadow-md relative overflow-hidden group hover:border-[#00ADB5] transition-colors"
      >
        <div className="flex items-start justify-between gap-2">
          <div className="space-y-1 z-10">
            <div className="flex items-center gap-1.5">
              <span className="text-[11px] uppercase tracking-wider text-[#8C93A0] font-bold block">
                Active Fleet
              </span>
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-extrabold text-white font-mono-data">
                {fleet.length.toLocaleString()} Assets
              </span>
            </div>
          </div>
          <div className="w-10 h-10 rounded-lg bg-[#00ADB5]/15 border-2 border-[#00ADB5]/30 flex items-center justify-center text-[#00ADB5] shrink-0">
            <Truck className="w-5 h-5" />
          </div>
        </div>

        {/* Provenance Lineage Citation Tag */}
        <div className="mt-2 pt-2 border-t border-[#242830] flex items-center justify-between text-[10px] font-mono-data text-[#8C93A0]">
          <span className="flex items-center gap-1">
            <Database className="w-3 h-3 text-[#00ADB5]" />
            <span>Source: Atera CAN-Bus 50Hz</span>
          </span>
          <span className="text-white font-semibold">10,000 Scale</span>
        </div>
      </div>

      {/* KPI 2: Disruption Status */}
      <div
        id="kpi-disruptions"
        className={`border-2 rounded-xl p-3.5 flex flex-col justify-between shadow-md relative overflow-hidden transition-colors ${
          hasStrandedAsset
            ? 'bg-rose-950/40 border-rose-500 hover:border-rose-400 animate-pulse'
            : simStorm && !executed
            ? 'bg-rose-950/30 border-[#FF2E63] hover:border-rose-400'
            : simStorm && executed
            ? 'bg-emerald-950/30 border-emerald-500 hover:border-emerald-400'
            : 'bg-[#181B20] border-[#2A2E35] hover:border-[#00ADB5]'
        }`}
      >
        <div className="flex items-start justify-between gap-2">
          <div className="space-y-1 z-10">
            <span className="text-[11px] uppercase tracking-wider text-[#8C93A0] font-bold block">
              Disruption Status
            </span>
            <div className="flex items-baseline gap-2">
              <span
                className={`text-2xl font-extrabold font-mono-data ${
                  hasStrandedAsset
                    ? 'text-rose-400'
                    : simStorm && !executed
                    ? 'text-[#FF2E63]'
                    : simStorm && executed
                    ? 'text-emerald-400'
                    : 'text-emerald-400'
                }`}
              >
                {disruptionStatus}
              </span>
            </div>
          </div>
          <div
            className={`w-10 h-10 rounded-lg border-2 flex items-center justify-center shrink-0 ${
              simStorm && !executed
                ? 'bg-[#FF2E63]/20 border-[#FF2E63] text-[#FF2E63]'
                : simStorm && executed
                ? 'bg-emerald-500/20 border-emerald-500 text-emerald-400'
                : 'bg-[#242932] border-[#2E3540] text-emerald-400'
            }`}
          >
            {simStorm && !executed ? (
              <CloudRain className="w-5 h-5 animate-pulse" />
            ) : simStorm && executed ? (
              <ShieldCheck className="w-5 h-5 text-emerald-400" />
            ) : (
              <CloudRain className="w-5 h-5 text-gray-500" />
            )}
          </div>
        </div>

        {/* Provenance Lineage Citation Tag */}
        <div className="mt-2 pt-2 border-t border-[#242830] flex items-center justify-between text-[10px] font-mono-data text-[#8C93A0]">
          <span className="flex items-center gap-1">
            <Database className="w-3 h-3 text-[#00ADB5]" />
            <span>Source: Met Office UK Doppler</span>
          </span>
          <span className="text-white font-semibold">Zone B Alert</span>
        </div>
      </div>

      {/* KPI 3: Avg Battery Level */}
      <div
        id="kpi-avg-battery"
        className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl p-3.5 flex flex-col justify-between shadow-md relative overflow-hidden group hover:border-[#00ADB5] transition-colors"
      >
        <div className="flex items-start justify-between gap-2">
          <div className="space-y-1 z-10">
            <span className="text-[11px] uppercase tracking-wider text-[#8C93A0] font-bold block">
              Avg Battery (SoC)
            </span>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-extrabold text-white font-mono-data">
                {avgBattery}%
              </span>
            </div>
          </div>
          <div className="w-10 h-10 rounded-lg bg-cyan-500/15 border-2 border-cyan-500/30 flex items-center justify-center text-cyan-400 shrink-0">
            <Bolt className="w-5 h-5" />
          </div>
        </div>

        {/* Provenance Lineage Citation Tag */}
        <div className="mt-2 pt-2 border-t border-[#242830] flex items-center justify-between text-[10px] font-mono-data text-[#8C93A0]">
          <span className="flex items-center gap-1">
            <Database className="w-3 h-3 text-[#00ADB5]" />
            <span>Source: CAN J1939 Telemetry</span>
          </span>
          <span className="text-white font-semibold">{totalDriverHours}h pool</span>
        </div>
      </div>

      {/* KPI 4: Est. Peak Power Cost */}
      <div
        id="kpi-power-cost"
        className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl p-3.5 flex flex-col justify-between shadow-md relative overflow-hidden group hover:border-amber-400 transition-colors"
      >
        <div className="flex items-start justify-between gap-2">
          <div className="space-y-1 z-10">
            <span className="text-[11px] uppercase tracking-wider text-[#8C93A0] font-bold block">
              Depot Utility Tariff
            </span>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-extrabold text-amber-400 font-mono-data">
                ${gridPriceSurge.toFixed(2)}/kWh
              </span>
            </div>
          </div>
          <div className="w-10 h-10 rounded-lg bg-amber-500/15 border-2 border-amber-500/30 flex items-center justify-center text-amber-400 shrink-0">
            <DollarSign className="w-5 h-5" />
          </div>
        </div>

        {/* Provenance Lineage Citation Tag */}
        <div className="mt-2 pt-2 border-t border-[#242830] flex items-center justify-between text-[10px] font-mono-data text-[#8C93A0]">
          <span className="flex items-center gap-1">
            <Database className="w-3 h-3 text-[#00ADB5]" />
            <span>Source: National Grid ESO Live</span>
          </span>
          <span className="text-white font-semibold">Real-Time API</span>
        </div>
      </div>
    </div>
  );
};
