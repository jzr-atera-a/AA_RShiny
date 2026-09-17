import React from 'react';
import {
  ResponsiveContainer,
  ComposedChart,
  Bar,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  CartesianGrid,
  ReferenceLine,
} from 'recharts';
import { HourlyChargingData, ScenarioMetrics } from '../types';
import { Zap, TrendingDown, ShieldAlert, Sparkles, DollarSign } from 'lucide-react';

interface ChargingSchedulePlotProps {
  data: HourlyChargingData[];
  executed: boolean;
  gridPriceSurge: number;
  metrics: ScenarioMetrics;
}

export const ChargingSchedulePlot: React.FC<ChargingSchedulePlotProps> = ({
  data,
  executed,
  gridPriceSurge,
  metrics,
}) => {
  // Peak tariff hours usually 16:00 - 19:00
  const peakTariffVal = Math.max(...data.map((d) => d.tariff));

  return (
    <div className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl overflow-hidden shadow-lg flex flex-col h-full">
      {/* Card Header */}
      <div className="px-4 py-3 border-b-2 border-[#2A2E35] bg-[#1C2026] flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <div className="p-1 rounded bg-[#00ADB5]/10 text-[#00ADB5] border border-[#00ADB5]/30">
            <Zap className="w-4 h-4" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-xs font-bold text-white uppercase tracking-wider">
                Automated EV Depot Charging Schedule
              </h3>
              <span className="text-[9px] font-mono-data text-[#8C93A0] bg-[#121417] px-1.5 py-0.5 rounded border border-[#2E3540]">
                Source: National Grid ESO Live
              </span>
            </div>
            <p className="text-[10px] text-[#8C93A0]">
              Dynamic Load-Balancing & Peak Tariff Avoidance
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <span
            className={`text-[11px] font-mono-data px-2 py-0.5 rounded border ${
              executed
                ? 'bg-emerald-950/50 text-emerald-400 border-emerald-700/60'
                : 'bg-amber-950/40 text-amber-300 border-amber-800/60'
            }`}
          >
            {executed ? 'Load Shift Active: 00:00–04:00' : 'Unoptimized Peak Draw: 16:00–19:00'}
          </span>
        </div>
      </div>

      {/* KPI Cost Breakdown & Transformer Protection Pill Bar */}
      <div className="px-4 py-2.5 bg-[#14171C] border-b border-[#242932] grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
        <div className="bg-[#181B20] p-2 rounded border border-[#2A2E35]">
          <span className="text-[10px] text-[#8C93A0] uppercase block">
            {executed ? 'Optimized Daily Tariff' : 'Baseline Unoptimized Tariff'}
          </span>
          <span className="text-sm font-bold font-mono-data text-white">
            ${executed ? metrics.optimizedCost.toFixed(2) : metrics.baselineCost.toFixed(2)}
          </span>
        </div>

        <div className="bg-[#181B20] p-2 rounded border border-[#2A2E35]">
          <span className="text-[10px] text-[#8C93A0] uppercase block">Peak Grid Avoidance</span>
          <span className="text-sm font-bold font-mono-data text-emerald-400 flex items-center gap-1">
            <TrendingDown className="w-3.5 h-3.5" />
            {executed ? '-300 kW at Peak' : '0 kW (Vulnerable)'}
          </span>
        </div>

        <div className="bg-[#181B20] p-2 rounded border border-[#2A2E35]">
          <span className="text-[10px] text-[#8C93A0] uppercase block">Transformer Headroom</span>
          <span className="text-sm font-bold font-mono-data text-emerald-400 flex items-center gap-1">
            <ShieldAlert className="w-3.5 h-3.5 text-emerald-400" />
            {executed ? '+220 kW (Safe)' : '+290 kW (Safe)'}
          </span>
        </div>

        <div className="bg-[#181B20] p-2 rounded border border-[#2A2E35]">
          <span className="text-[10px] text-[#8C93A0] uppercase block">Net Daily Savings</span>
          <span className="text-sm font-bold font-mono-data text-[#00ADB5] flex items-center gap-1">
            <DollarSign className="w-3.5 h-3.5" />
            ${metrics.costSaved.toFixed(2)} / day
          </span>
        </div>
      </div>

      {/* Hardware Protection Banner */}
      <div className="px-4 py-1.5 bg-emerald-950/30 border-b border-emerald-900/50 flex flex-wrap items-center justify-between gap-2 text-[11px] font-mono-data">
        <div className="flex items-center gap-2 text-emerald-300">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
          <span>HARDWARE GUARD: Substation Breaker Hard-Cap Enforced at 600 kW (OCPP 2.0.1 Staggered Queue)</span>
        </div>
        <span className="text-emerald-400 font-bold bg-emerald-900/60 px-2 py-0.5 rounded border border-emerald-700">
          Peak Surcharge: $0.00
        </span>
      </div>

      {/* Dual Axis Plot Area */}
      <div className="p-2 flex-1 min-h-[340px] w-full">
        <ResponsiveContainer width="100%" height={340}>
          <ComposedChart
            data={data}
            margin={{ top: 15, right: 20, bottom: 20, left: 10 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#252A33" vertical={false} />

            <XAxis
              dataKey="hour"
              stroke="#8C93A0"
              fontSize={10}
              tickLine={false}
              interval={2}
            />

            {/* Left Axis: Depot Fleet Power Demand (kW) - Domain up to 650 kW to show full physical transformer limit */}
            <YAxis
              yAxisId="left"
              orientation="left"
              stroke="#00ADB5"
              fontSize={10}
              domain={[0, 650]}
              tickLine={false}
              label={{
                value: 'Depot Demand (kW)',
                angle: -90,
                position: 'insideLeft',
                fill: '#00ADB5',
                fontSize: 10,
                offset: 5,
              }}
            />

            {/* Right Axis: Grid Price ($/kWh) */}
            <YAxis
              yAxisId="right"
              orientation="right"
              stroke="#FF2E63"
              fontSize={10}
              domain={[0, Math.max(0.7, peakTariffVal * 1.1)]}
              tickLine={false}
              tickFormatter={(val) => `$${val.toFixed(2)}`}
              label={{
                value: 'Grid Rate ($/kWh)',
                angle: 90,
                position: 'insideRight',
                fill: '#FF2E63',
                fontSize: 10,
                offset: 5,
              }}
            />

            <Tooltip
              content={({ active, payload, label }) => {
                if (!active || !payload || !payload.length) return null;
                const item = payload[0].payload as HourlyChargingData;
                return (
                  <div className="bg-[#181B20] border border-[#2A2E35] p-2.5 rounded-lg shadow-2xl text-xs font-mono-data">
                    <div className="text-white font-bold mb-1.5 border-b border-[#2A2E35] pb-1">
                      Time Slot: {label}
                    </div>
                    <div className="space-y-1">
                      <div className="flex items-center justify-between gap-4 text-[#00ADB5]">
                        <span>Fleet Power Demand:</span>
                        <b>{item.activeDemand} kW</b>
                      </div>
                      <div className="flex items-center justify-between gap-4 text-[#FF2E63]">
                        <span>Grid Tariff:</span>
                        <b>${item.tariff.toFixed(2)} / kWh</b>
                      </div>
                      <div className="flex items-center justify-between gap-4 text-[#8C93A0] text-[10px] pt-1 border-t border-[#242932]">
                        <span>Cost in this Hour:</span>
                        <b className="text-white">
                          ${(item.activeDemand * item.tariff).toFixed(2)}
                        </b>
                      </div>
                    </div>
                  </div>
                );
              }}
            />

            <Legend
              verticalAlign="top"
              height={32}
              formatter={(value) => (
                <span className="text-xs text-[#CBD5E1] font-mono-data mr-4">
                  {value}
                </span>
              )}
            />

            {/* Physical Substation Transformer Breaker Hardware Reference Line (600 kW) */}
            <ReferenceLine
              yAxisId="left"
              y={600}
              stroke="#EF4444"
              strokeWidth={2}
              strokeDasharray="4 4"
              label={{
                value: 'SUBSTATION TRANSFORMER CAPACITY (600 kW BREAKER)',
                fill: '#EF4444',
                fontSize: 10,
                position: 'insideTopLeft',
              }}
            />

            {/* Safe Operational Threshold (500 kW) */}
            <ReferenceLine
              yAxisId="left"
              y={500}
              stroke="#F59E0B"
              strokeWidth={1}
              strokeDasharray="2 2"
              label={{
                value: 'Safe Operating Ceiling (500 kW)',
                fill: '#F59E0B',
                fontSize: 9,
                position: 'insideBottomLeft',
              }}
            />

            {/* Reference Line for Tariff Surge Window (16:00 - 18:00) */}
            <ReferenceLine
              yAxisId="right"
              y={gridPriceSurge * 2}
              stroke="#FF2E63"
              strokeDasharray="3 3"
              label={{
                value: `Peak Surge ($${(gridPriceSurge * 2).toFixed(2)})`,
                fill: '#FF2E63',
                fontSize: 10,
                position: 'top',
              }}
            />

            {/* Bar: Fleet Power Demand (kW) */}
            <Bar
              yAxisId="left"
              dataKey="activeDemand"
              name="Fleet Power Demand (kW)"
              fill="#00ADB5"
              radius={[3, 3, 0, 0]}
              maxBarSize={22}
            />

            {/* Line: Grid Price ($/kWh) */}
            <Line
              yAxisId="right"
              type="monotone"
              dataKey="tariff"
              name="Grid Price ($/kWh)"
              stroke="#FF2E63"
              strokeWidth={2.5}
              dot={{ r: 2.5, fill: '#FF2E63' }}
              activeDot={{ r: 5, fill: '#FF2E63' }}
            />
          </ComposedChart>
        </ResponsiveContainer>
      </div>

      {/* Card Footer with Load-Balancing Guard Plain-English Description */}
      <div className="px-4 py-2.5 bg-[#14171C] border-t border-[#2A2E35] text-[11px] text-[#8C93A0] flex flex-wrap items-center justify-between gap-2">
        <span>Staggers depot charging windows across 22:00–04:00 with OCPP 2.0.1 dynamic current throttling.</span>
        <span className="font-mono-data text-emerald-400 font-medium">
          {executed
            ? '✓ Guard Enforced: Peak clamped to 380 kW (+220 kW safety margin under 600 kW breaker)'
            : '⚠️ Baseline Schedule: Charges during peak tariffs without dynamic transformer current throttling'}
        </span>
      </div>
    </div>
  );
};
