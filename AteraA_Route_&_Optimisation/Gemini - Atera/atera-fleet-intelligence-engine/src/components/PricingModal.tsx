import React, { useState } from 'react';
import { 
  X, 
  Check, 
  ShieldCheck, 
  CreditCard, 
  Zap, 
  Sparkles, 
  Download, 
  ChevronRight, 
  AlertCircle 
} from 'lucide-react';
import { PRICING_TIERS } from '../data/fleetData';
import { PricingTierId } from '../types';

interface PricingModalProps {
  isOpen: boolean;
  onClose: () => void;
  activeTier: PricingTierId;
  onSelectTier: (tierId: PricingTierId) => void;
}

export const PricingModal: React.FC<PricingModalProps> = ({
  isOpen,
  onClose,
  activeTier,
  onSelectTier,
}) => {
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'annual'>('monthly');
  const [invoiceToast, setInvoiceToast] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleDownloadInvoice = (invoiceId: string) => {
    setInvoiceToast(`Invoice #${invoiceId} generated & downloaded.`);
    setTimeout(() => setInvoiceToast(null), 3000);
  };

  return (
    <div 
      role="dialog" 
      aria-modal="true" 
      aria-labelledby="pricing-modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/80 backdrop-blur-sm overflow-y-auto"
    >
      <div 
        className="bg-[#181B20] border-2 border-[#3A404D] rounded-2xl w-full max-w-5xl shadow-2xl overflow-hidden flex flex-col my-auto max-h-[95vh]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-6 py-5 border-b-2 border-[#2A2E35] bg-[#1C2026] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-[#00ADB5]/20 border border-[#00ADB5]/40 text-[#00ADB5]">
              <CreditCard className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 id="pricing-modal-title" className="text-base font-bold text-white uppercase tracking-wider">
                  Plan & Subscription Billing
                </h2>
                <span className="bg-[#00ADB5]/20 text-[#00ADB5] border border-[#00ADB5]/40 text-[10px] font-mono-data px-2 py-0.5 rounded font-bold">
                  REGULATION COMPLIANT PRICING
                </span>
              </div>
              <p className="text-xs text-[#8C93A0]">
                Upfront transparent commercial pricing. Change tiers anytime with instant feature unlock.
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            aria-label="Close pricing modal"
            className="p-2 rounded-lg bg-[#242932] hover:bg-[#2C323D] text-[#8C93A0] hover:text-white border border-[#393E46] transition-colors focus-visible:ring-2 focus-visible:ring-[#00ADB5]"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content Body */}
        <div className="p-6 overflow-y-auto space-y-6">
          {/* Billing Cycle Switch */}
          <div className="flex items-center justify-center gap-3">
            <span className={`text-xs font-medium ${billingCycle === 'monthly' ? 'text-white' : 'text-[#8C93A0]'}`}>
              Billed Monthly
            </span>
            <button
              onClick={() => setBillingCycle(b => b === 'monthly' ? 'annual' : 'monthly')}
              aria-label="Toggle annual or monthly billing"
              className="w-14 h-7 bg-[#121417] border-2 border-[#3A404D] rounded-full p-0.5 flex items-center transition-colors focus-visible:ring-2 focus-visible:ring-[#00ADB5]"
            >
              <div 
                className={`w-5 h-5 rounded-full bg-[#00ADB5] transition-transform ${billingCycle === 'annual' ? 'translate-x-7' : 'translate-x-0'}`} 
              />
            </button>
            <div className="flex items-center gap-1.5">
              <span className={`text-xs font-medium ${billingCycle === 'annual' ? 'text-white' : 'text-[#8C93A0]'}`}>
                Billed Annually
              </span>
              <span className="bg-emerald-950/60 border border-emerald-700 text-emerald-400 text-[10px] font-bold px-2 py-0.5 rounded-full">
                SAVE 20%
              </span>
            </div>
          </div>

          {/* Pricing Tiers Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 items-stretch">
            {PRICING_TIERS.map((tier) => {
              const isActive = activeTier === tier.id;
              const price = billingCycle === 'annual' ? tier.priceAnnualMonthly : tier.priceMonthly;

              return (
                <div
                  key={tier.id}
                  className={`rounded-xl p-5 flex flex-col justify-between transition-all relative border-2 ${
                    isActive
                      ? 'bg-[#1C222B] border-[#00ADB5] shadow-lg shadow-[#00ADB5]/10 ring-1 ring-[#00ADB5]'
                      : tier.popular
                      ? 'bg-[#181B20] border-amber-500/50 hover:border-amber-400'
                      : 'bg-[#181B20] border-[#2A2E35] hover:border-[#393E46]'
                  }`}
                >
                  {/* Badge */}
                  {isActive ? (
                    <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-[#00ADB5] text-[#121417] text-[10px] font-extrabold uppercase px-3 py-0.5 rounded-full shadow font-mono-data tracking-wider">
                      Current Active Plan
                    </div>
                  ) : tier.popular ? (
                    <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-amber-400 text-[#121417] text-[10px] font-extrabold uppercase px-3 py-0.5 rounded-full shadow font-mono-data tracking-wider">
                      Most Popular
                    </div>
                  ) : null}

                  <div>
                    {/* Title & Description */}
                    <div className="flex items-center justify-between mb-1">
                      <h3 className="text-base font-bold text-white">{tier.name}</h3>
                      <span className="text-[11px] font-mono-data text-[#8C93A0]">
                        {tier.vehicleLimit === 10000 ? '10,000+ Assets' : `Up to ${tier.vehicleLimit} Assets`}
                      </span>
                    </div>
                    <p className="text-xs text-[#8C93A0] min-h-[34px] mb-4">
                      {tier.description}
                    </p>

                    {/* Price display */}
                    <div className="mb-5 pb-4 border-b border-[#2A2E35]">
                      <div className="flex items-baseline gap-1">
                        <span className="text-3xl font-extrabold text-white font-mono-data">
                          ${price}
                        </span>
                        <span className="text-xs text-[#8C93A0]">/ month</span>
                      </div>
                      <span className="text-[10px] text-[#6B7280] block font-mono-data mt-0.5">
                        {billingCycle === 'annual' ? 'Billed $ ' + (price * 12) + '/year' : 'Month-to-month flexibility'}
                      </span>
                    </div>

                    {/* Features list */}
                    <div className="space-y-2.5 mb-6">
                      <span className="text-[10px] uppercase font-bold text-[#8C93A0] tracking-wider block font-mono-data">
                        Included Capabilities:
                      </span>
                      {tier.features.map((feat, idx) => (
                        <div key={idx} className="flex items-start gap-2 text-xs">
                          <div className="p-0.5 rounded bg-emerald-950/80 text-emerald-400 border border-emerald-800 shrink-0 mt-0.5">
                            <Check className="w-3 h-3" />
                          </div>
                          <span className="text-[#C5CDD9] leading-snug">{feat}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Action button */}
                  <div className="pt-2">
                    <button
                      onClick={() => onSelectTier(tier.id)}
                      disabled={isActive}
                      className={`w-full py-2.5 px-4 rounded-lg text-xs font-bold uppercase tracking-wider transition-all flex items-center justify-center gap-2 cursor-pointer border-2 ${
                        isActive
                          ? 'bg-[#242932] text-emerald-400 border-emerald-700 cursor-default'
                          : 'bg-[#00ADB5] hover:bg-[#009299] text-[#121417] border-[#00ADB5] shadow-md hover:shadow-lg'
                      }`}
                    >
                      {isActive ? (
                        <>
                          <ShieldCheck className="w-4 h-4" />
                          <span>Active Subscription</span>
                        </>
                      ) : (
                        <>
                          <Zap className="w-4 h-4 fill-current" />
                          <span>Switch to {tier.name}</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Billing Receipts & Compliance strip */}
          <div className="bg-[#14171C] border-2 border-[#2A2E35] rounded-xl p-4 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded bg-[#242932] text-[#9CA3AF] border border-[#2E3540]">
                <ShieldCheck className="w-5 h-5 text-emerald-400" />
              </div>
              <div>
                <span className="text-xs font-bold text-white block">
                  Enterprise Commercial License & ISO 27001 SLA
                </span>
                <span className="text-[11px] text-[#8C93A0]">
                  Direct SEPA / BACS / Corporate Credit Card debit. Guaranteed 99.99% telematics ingress SLA.
                </span>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <button
                onClick={() => handleDownloadInvoice('INV-2026-0894')}
                className="bg-[#242932] hover:bg-[#2E3540] text-white border border-[#3A404D] px-3 py-1.5 rounded text-xs font-medium flex items-center gap-1.5 transition-colors cursor-pointer"
              >
                <Download className="w-3.5 h-3.5 text-[#00ADB5]" />
                <span>Download VAT Invoice</span>
              </button>
            </div>
          </div>

          {invoiceToast && (
            <div className="p-2.5 bg-emerald-950/60 border border-emerald-700 text-emerald-300 text-xs rounded-lg flex items-center gap-2">
              <Check className="w-4 h-4 text-emerald-400" />
              <span>{invoiceToast}</span>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t-2 border-[#2A2E35] bg-[#14171C] flex items-center justify-between">
          <span className="text-[11px] text-[#8C93A0]">
            Prices exclude applicable VAT. Fleet cancelable anytime without lock-in.
          </span>
          <button
            onClick={onClose}
            className="bg-[#242932] hover:bg-[#2C323D] text-white font-medium text-xs px-4 py-2 rounded-lg border border-[#3A404D] transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};
