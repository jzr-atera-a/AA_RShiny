import React, { useState } from 'react';
import { 
  X, 
  Database, 
  Check, 
  ExternalLink, 
  Copy, 
  ShieldCheck, 
  Radio, 
  Clock, 
  Zap 
} from 'lucide-react';
import { DATA_LINEAGE_SOURCES } from '../data/fleetData';
import { DataLineageSource } from '../types';

interface DataLineageModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const DataLineageModal: React.FC<DataLineageModalProps> = ({
  isOpen,
  onClose,
}) => {
  const [copiedId, setCopiedId] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleCopyCitation = (source: DataLineageSource) => {
    const text = `Provenance Citation: [${source.name}] provided by ${source.provider}. Endpoint: ${source.endpoint}. License: ${source.license}. Verified confidence: ${source.confidencePct}%.`;
    navigator.clipboard.writeText(text);
    setCopiedId(source.id);
    setTimeout(() => setCopiedId(null), 2500);
  };

  return (
    <div 
      role="dialog" 
      aria-modal="true" 
      aria-labelledby="data-lineage-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/80 backdrop-blur-sm overflow-y-auto"
    >
      <div 
        className="bg-[#181B20] border-2 border-[#00ADB5]/50 rounded-2xl w-full max-w-4xl shadow-2xl overflow-hidden flex flex-col my-auto max-h-[90vh]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-6 py-5 border-b-2 border-[#2A2E35] bg-[#1C2026] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-[#00ADB5]/20 border border-[#00ADB5]/40 text-[#00ADB5]">
              <Database className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 id="data-lineage-title" className="text-base font-bold text-white uppercase tracking-wider">
                  Data Lineage & Telemetry Provenance Registry
                </h2>
                <span className="bg-emerald-950/60 border border-emerald-700 text-emerald-400 text-[10px] font-mono-data px-2 py-0.5 rounded font-bold">
                  TRUST & COMPLIANCE
                </span>
              </div>
              <p className="text-xs text-[#8C93A0]">
                Cryptographic audit trail of all upstream telemetry, weather feeds, and grid tariff sources.
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            aria-label="Close data lineage modal"
            className="p-2 rounded-lg bg-[#242932] hover:bg-[#2C323D] text-[#8C93A0] hover:text-white border border-[#393E46] transition-colors focus-visible:ring-2 focus-visible:ring-[#00ADB5]"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* List of Data Sources */}
        <div className="p-6 overflow-y-auto space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {DATA_LINEAGE_SOURCES.map((source) => (
              <div 
                key={source.id}
                className="bg-[#14171C] border-2 border-[#2A2E35] hover:border-[#00ADB5]/50 rounded-xl p-4 flex flex-col justify-between transition-colors"
              >
                <div>
                  <div className="flex items-start justify-between gap-2 mb-2">
                    <div>
                      <span className="text-[10px] font-bold uppercase font-mono-data px-2 py-0.5 rounded bg-[#242932] text-[#00ADB5] border border-[#2E3540] inline-block mb-1">
                        {source.category}
                      </span>
                      <h3 className="text-xs font-bold text-white leading-snug">
                        {source.name}
                      </h3>
                    </div>
                    <span className="flex items-center gap-1 text-[10px] font-mono-data text-emerald-400 bg-emerald-950/40 px-2 py-0.5 rounded border border-emerald-800 shrink-0">
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                      {source.confidencePct}% Conf
                    </span>
                  </div>

                  <p className="text-[11px] text-[#8C93A0] mb-3">
                    Provider: <strong className="text-[#C5CDD9]">{source.provider}</strong>
                  </p>

                  <div className="space-y-1.5 bg-[#181B20] p-2.5 rounded border border-[#242932] font-mono-data text-[10px] text-[#8C93A0] mb-3">
                    <div className="truncate">
                      <span className="text-[#6B7280]">Endpoint: </span>
                      <span className="text-[#00ADB5]">{source.endpoint}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span>Rate: <strong className="text-white">{source.refreshInterval}</strong></span>
                      <span>Latency: <strong className="text-emerald-400">{source.latencyMs}ms</strong></span>
                    </div>
                    <div>
                      <span className="text-[#6B7280]">License: </span>
                      <span className="text-[#A3ADC0]">{source.license}</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center justify-between pt-2 border-t border-[#242932]">
                  <span className="text-[10px] text-[#6B7280] font-mono-data">
                    Sync: {source.lastSync}
                  </span>
                  <button
                    onClick={() => handleCopyCitation(source)}
                    className="bg-[#242932] hover:bg-[#2E3540] text-[#00ADB5] hover:text-white px-2.5 py-1 rounded text-[11px] font-medium border border-[#3A404D] flex items-center gap-1.5 transition-colors cursor-pointer"
                  >
                    {copiedId === source.id ? (
                      <>
                        <Check className="w-3.5 h-3.5 text-emerald-400" />
                        <span className="text-emerald-400">Copied!</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-3.5 h-3.5" />
                        <span>Copy Citation</span>
                      </>
                    )}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t-2 border-[#2A2E35] bg-[#14171C] flex items-center justify-between text-xs">
          <div className="flex items-center gap-2 text-[#8C93A0]">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <span>ISO/IEC 27001 Certified Cryptographic Telemetry Lineage</span>
          </div>
          <button
            onClick={onClose}
            className="bg-[#242932] hover:bg-[#2C323D] text-white font-medium text-xs px-4 py-1.5 rounded-lg border border-[#3A404D] transition-colors"
          >
            Close Registry
          </button>
        </div>
      </div>
    </div>
  );
};
