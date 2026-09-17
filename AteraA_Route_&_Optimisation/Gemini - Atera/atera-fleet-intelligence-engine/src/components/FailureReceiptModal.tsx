import React from 'react';
import { X, AlertOctagon, ArrowRight, Zap, ShieldAlert, DollarSign, CloudRain } from 'lucide-react';

interface FailureReceiptModalProps {
  isOpen: boolean;
  onClose: () => void;
  onApplyChaosMode?: () => void;
}

export const FailureReceiptModal: React.FC<FailureReceiptModalProps> = ({
  isOpen,
  onClose,
  onApplyChaosMode,
}) => {
  if (!isOpen) return null;

  return (
    <div 
      role="dialog" 
      aria-modal="true" 
      aria-labelledby="failure-modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/85 backdrop-blur-sm overflow-y-auto"
    >
      <div 
        className="bg-[#181B20] border-2 border-rose-500/80 rounded-2xl w-full max-w-4xl shadow-2xl overflow-hidden flex flex-col my-auto max-h-[92vh]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-6 py-4 border-b-2 border-[#2A2E35] bg-rose-950/40 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-rose-500/20 border border-rose-500/50 text-rose-400">
              <AlertOctagon className="w-5 h-5 animate-pulse" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 id="failure-modal-title" className="text-base font-bold text-white uppercase tracking-wider">
                  Operational Breakdown Receipt: The Transformer Overload Contradiction
                </h2>
                <span className="bg-rose-950 text-rose-300 border border-rose-800 text-[10px] font-mono-data px-2 py-0.5 rounded font-bold">
                  FAILURE DETECTED
                </span>
              </div>
              <p className="text-xs text-[#CBD5E1]">
                Visual proof of the unmanaged load-shifting failure called in our technical review.
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            aria-label="Close failure receipt modal"
            className="p-1.5 rounded-lg bg-[#242932] hover:bg-[#2C323D] text-[#8C93A0] hover:text-white border border-[#393E46] transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 overflow-y-auto space-y-5 bg-[#121417]">
          {/* Visual Screenshot of the Failure */}
          <div className="border-2 border-rose-900 rounded-xl overflow-hidden shadow-2xl relative">
            <div className="bg-[#1A1D24] px-3 py-1.5 border-b border-rose-900/60 flex items-center justify-between text-xs font-mono-data text-[#8C93A0]">
              <span>RECEIPT SCREENSHOT: Real-World Invalidation of the Happy-Path Optimization</span>
              <span className="text-rose-400 font-bold">2 Direct Contradictions</span>
            </div>
            <img 
              src="/src/assets/images/atera_failure_contradiction_1789565965675.jpg" 
              alt="Screenshot of Atera Fleet Intelligence displaying two contradictory failure states"
              className="w-full h-auto object-cover"
            />
          </div>

          {/* Breakdown Analysis */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
            {/* Contradiction 1 */}
            <div className="p-4 rounded-xl bg-[#181B20] border-2 border-rose-900/60 space-y-2">
              <div className="flex items-center gap-2 text-rose-400 font-bold uppercase tracking-wide">
                <CloudRain className="w-4 h-4" />
                <span>Contradiction 1: Phantom Reroute vs Stranded Van</span>
              </div>
              <p className="text-[#C5CDD9] leading-relaxed">
                The KPI banner declares <strong className="text-emerald-400">"Disruption Status: 100% Mitigated"</strong> and draws a clean green bypass line on the map.
                However, vehicle <strong className="text-rose-400">VAN-102</strong> is pinned dead center inside the red flood polygon with <strong className="text-white font-mono-data">Speed: 0 mph (Motor Waterlogged)</strong>.
              </p>
              <div className="p-2 bg-[#121417] rounded border border-rose-950 text-[11px] font-mono-data text-rose-300">
                Cost to Customer: Driver is stranded with ruined cargo while dispatch software claims delivery is on schedule.
              </div>
            </div>

            {/* Contradiction 2 */}
            <div className="p-4 rounded-xl bg-[#181B20] border-2 border-rose-900/60 space-y-2">
              <div className="flex items-center gap-2 text-rose-400 font-bold uppercase tracking-wide">
                <Zap className="w-4 h-4" />
                <span>Contradiction 2: Substation Breaker Blowout</span>
              </div>
              <p className="text-[#C5CDD9] leading-relaxed">
                The algorithm dumped all charging into the 00:00–04:00 off-peak rate window.
                This spikes depot power demand to <strong className="text-rose-400">850 kW</strong>, blowing the physical <strong className="text-white">600 kW</strong> substation limit.
                The software still touts <strong className="text-emerald-400">"Daily Savings: $118.00"</strong> right beside an astronomical <strong className="text-rose-400">$12,400 National Grid Peak Overload Penalty</strong>.
              </p>
              <div className="p-2 bg-[#121417] rounded border border-rose-950 text-[11px] font-mono-data text-rose-300">
                Cost to Customer: $12,400 demand penalty invoice + depot dark at 07:00 with dead vehicle batteries.
              </div>
            </div>
          </div>

          {/* Active Guardrails Implemented Section */}
          <div className="p-4 rounded-xl bg-[#151921] border-2 border-emerald-700/60 space-y-3 text-xs">
            <div className="flex items-center gap-2 text-emerald-400 font-bold uppercase tracking-wider">
              <ShieldAlert className="w-4 h-4" />
              <span>Guardrails Implemented to Defend Against System Failures</span>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-[11px]">
              <div className="p-3 bg-[#111317] rounded-lg border border-[#2A2E35] space-y-1">
                <b className="text-white block">1. CartoDB Missing API Key & Watermark Guard</b>
                <p className="text-[#8C93A0]">
                  CartoDB basemap watermarking and 401/403 rate-limits are prevented by default with a resilient <strong className="text-emerald-400">Keyless Dark OSM</strong> layer and a procedural <strong className="text-[#00ADB5]">Offline Vector Basemap</strong> with zero external API key requirements.
                </p>
              </div>
              <div className="p-3 bg-[#111317] rounded-lg border border-[#2A2E35] space-y-1">
                <b className="text-white block">2. Triple-Guarded Destructive Data Erasure</b>
                <p className="text-[#8C93A0]">
                  Replaced the unshielded 1-click delete button with a strict confirmation barrier: requires typing <strong className="text-rose-400 font-mono-data">CONFIRM-PERMANENT-WIPE</strong>, dual loss acknowledgments, and a 3-second safety interlock countdown.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-3 border-t-2 border-[#2A2E35] bg-[#181B20] flex flex-wrap items-center justify-between gap-3 text-xs">
          <span className="text-[#8C93A0]">
            Confirmed prediction: Load-shifting without physical circuit constraints destroys transformer hardware.
          </span>
          <div className="flex items-center gap-2">
            {onApplyChaosMode && (
              <button
                onClick={() => {
                  onApplyChaosMode();
                  onClose();
                }}
                className="bg-rose-600 hover:bg-rose-500 text-white font-bold px-3.5 py-1.5 rounded-lg transition-colors cursor-pointer"
              >
                Inject Failure Into Live UI
              </button>
            )}
            <button
              onClick={onClose}
              className="bg-[#242932] hover:bg-[#2C323D] text-white px-4 py-1.5 rounded-lg border border-[#3A404D]"
            >
              Close Receipt
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
