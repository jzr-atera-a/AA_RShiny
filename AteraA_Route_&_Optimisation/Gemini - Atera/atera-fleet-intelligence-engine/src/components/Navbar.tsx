import React, { useEffect, useState } from 'react';
import { 
  Radio, 
  Zap, 
  Sliders, 
  AlertTriangle, 
  ShieldCheck, 
  Clock, 
  MapPin, 
  CreditCard, 
  Trash2, 
  Database, 
  FileCode2, 
  Menu, 
  X, 
  Eye, 
  Sparkles,
  ChevronDown,
  ShieldAlert
} from 'lucide-react';
import { PricingTierId } from '../types';

interface NavbarProps {
  currentScreen: 'dispatch' | 'optimizer';
  onSelectScreen: (screen: 'dispatch' | 'optimizer') => void;
  simStorm: boolean;
  executed: boolean;
  gridPriceSurge: number;
  activeTier: PricingTierId;
  onOpenPricing: () => void;
  onOpenDeleteAccount: () => void;
  onOpenDataLineage: () => void;
  onOpenRShiny: () => void;
  onOpenFailureReceipt?: () => void;
  highContrast: boolean;
  onToggleHighContrast: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  currentScreen,
  onSelectScreen,
  simStorm,
  executed,
  gridPriceSurge,
  activeTier,
  onOpenPricing,
  onOpenDeleteAccount,
  onOpenDataLineage,
  onOpenRShiny,
  onOpenFailureReceipt,
  highContrast,
  onToggleHighContrast,
}) => {
  const [timeStr, setTimeStr] = useState<string>('');
  const [mobileMenuOpen, setMobileMenuOpen] = useState<boolean>(false);

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setTimeStr(
        now.toLocaleTimeString('en-GB', {
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
          timeZone: 'Europe/London',
        }) + ' BST'
      );
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  const getTierPriceText = () => {
    switch (activeTier) {
      case 'starter':
        return 'Starter ($149/mo)';
      case 'pro':
        return 'Fleet Pro ($299/mo)';
      case 'enterprise':
      default:
        return 'Enterprise Grid ($499/mo)';
    }
  };

  return (
    <header className="bg-[#16191E] border-b-2 border-[#2A2E35] sticky top-0 z-50 shadow-md">
      {/* Top Regulation, Lineage & 1-Click Wipe Strip (Always upfront & visible) */}
      <div className="bg-[#0F1115] border-b border-[#242830] px-3 sm:px-6 py-1.5 flex flex-wrap items-center justify-between gap-2 text-[11px]">
        {/* Left: Visible Pricing Tiers & Data Lineage Citation */}
        <div className="flex flex-wrap items-center gap-3">
          <button
            onClick={onOpenPricing}
            className="flex items-center gap-1.5 text-white hover:text-[#00ADB5] transition-colors focus-visible:ring-1 focus-visible:ring-[#00ADB5]"
            title="View upfront pricing tiers ($149 - $499/mo)"
          >
            <span className="bg-[#00ADB5]/20 text-[#00ADB5] border border-[#00ADB5]/40 text-[9px] font-mono-data px-1.5 py-0.2 rounded font-bold uppercase">
              Tiers $149 - $499/mo
            </span>
            <span className="font-semibold text-white">Active Plan: {getTierPriceText()}</span>
            <ChevronDown className="w-3 h-3 text-[#8C93A0]" />
          </button>

          <span className="text-[#393E46] hidden sm:inline">|</span>

          {/* Lineage badge */}
          <button
            onClick={onOpenDataLineage}
            className="hidden md:flex items-center gap-1 text-[#8C93A0] hover:text-white transition-colors"
          >
            <Database className="w-3 h-3 text-[#00ADB5]" />
            <span>Data Lineage: <strong className="text-[#C5CDD9]">National Grid ESO & Met Office Doppler</strong></span>
          </button>
        </div>

        {/* Right: Prominent 1-Click Delete Account, Contrast Toggle, and R Shiny Export */}
        <div className="flex items-center gap-2">
          {/* High Contrast Toggle */}
          <button
            onClick={onToggleHighContrast}
            title={highContrast ? 'Disable high contrast mode' : 'Enable WCAG high contrast mode'}
            aria-label="Toggle High Contrast Mode"
            className={`px-2 py-0.5 rounded text-[10px] font-bold border transition-colors flex items-center gap-1 ${
              highContrast
                ? 'bg-amber-400 text-black border-amber-300'
                : 'bg-[#1C2026] text-[#A3ADC0] border-[#2E3540] hover:text-white'
            }`}
          >
            <Eye className="w-3 h-3" />
            <span className="hidden sm:inline">Contrast: {highContrast ? 'MAX' : 'STD'}</span>
          </button>

          {/* Single-file app.R export */}
          <button
            onClick={onOpenRShiny}
            title="View complete single-file R Shiny application (app.R)"
            className="bg-[#1C2026] hover:bg-[#252A33] text-[#00ADB5] border border-[#2E3540] px-2 py-0.5 rounded text-[10px] font-bold font-mono-data flex items-center gap-1 transition-colors"
          >
            <FileCode2 className="w-3 h-3" />
            <span>app.R</span>
          </button>

          {/* Failure Receipt Modal Trigger */}
          {onOpenFailureReceipt && (
            <button
              onClick={onOpenFailureReceipt}
              title="View Failure Receipt & Invalidation Proof"
              className="bg-rose-950/70 hover:bg-rose-900 text-rose-300 border border-rose-600 px-2 py-0.5 rounded text-[10px] font-bold flex items-center gap-1 transition-colors cursor-pointer"
            >
              <AlertTriangle className="w-3 h-3 text-rose-400" />
              <span>Failure Receipt</span>
            </button>
          )}

          {/* Prominent Guarded Delete Account Button */}
          <button
            id="btn-nav-delete-account"
            onClick={onOpenDeleteAccount}
            title="Guarded GDPR Art. 17 Erasure with Two-Factor Verification"
            aria-label="Guarded Account & Telematics Erasure"
            className="bg-rose-950/40 hover:bg-rose-900/60 text-rose-300 hover:text-white border border-rose-500/70 px-2.5 py-0.5 rounded font-bold text-[10px] flex items-center gap-1.5 transition-all shadow-sm cursor-pointer"
          >
            <ShieldAlert className="w-3 h-3 text-rose-400 shrink-0" />
            <span>GDPR Erasure (Guarded)</span>
          </button>
        </div>
      </div>

      {/* Main Navbar Row */}
      <div className="w-full px-3 sm:px-6 py-2.5 flex items-center justify-between gap-3">
        {/* Brand identity */}
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-[#00ADB5] to-[#007B80] flex items-center justify-center shadow-lg shadow-[#00ADB5]/20 shrink-0">
            <Radio className="w-4 h-4 text-white animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-[15px] tracking-wide text-white uppercase">
                Atera <span className="text-[#00ADB5]">Fleet Intelligence</span>
              </span>
              <span className="bg-[#242932] text-[#9CA3AF] text-[9px] uppercase font-mono-data px-1.5 py-0.2 rounded border border-[#2E3540]">
                v1.2-POC
              </span>
            </div>
            <div className="hidden sm:flex items-center gap-2 text-[10px] text-[#8C93A0]">
              <span className="inline-block w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
              <span>Commercial Telemetry Ingest: London Corridor Sector</span>
            </div>
          </div>
        </div>

        {/* Screen Navigation Tabs (Desktop) */}
        <nav 
          role="navigation" 
          aria-label="Main Dispatch Views"
          className="hidden md:flex items-center bg-[#121417] p-1 rounded-xl border-2 border-[#2A2E35]"
        >
          <button
            id="tab-dispatch-screen"
            onClick={() => onSelectScreen('dispatch')}
            aria-selected={currentScreen === 'dispatch'}
            role="tab"
            className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
              currentScreen === 'dispatch'
                ? 'bg-[#00ADB5] text-[#121417] shadow-md ring-1 ring-[#00ADB5]'
                : 'text-[#9CA3AF] hover:text-[#E0E0E0] hover:bg-[#1E2229]'
            }`}
          >
            <MapPin className="w-3.5 h-3.5" />
            <span>Screen 1: Live Dispatch Control Center</span>
            {simStorm && (
              <span
                className={`text-[9px] px-1.5 py-0.2 rounded font-mono-data font-bold ${
                  executed
                    ? 'bg-emerald-900/80 text-emerald-200 border border-emerald-700'
                    : 'bg-rose-900/80 text-rose-200 border border-rose-700 animate-pulse'
                }`}
              >
                {executed ? 'Resolved' : 'Alert'}
              </span>
            )}
          </button>

          <button
            id="tab-optimizer-screen"
            onClick={() => onSelectScreen('optimizer')}
            aria-selected={currentScreen === 'optimizer'}
            role="tab"
            className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
              currentScreen === 'optimizer'
                ? 'bg-[#00ADB5] text-[#121417] shadow-md ring-1 ring-[#00ADB5]'
                : 'text-[#9CA3AF] hover:text-[#E0E0E0] hover:bg-[#1E2229]'
            }`}
          >
            <Sliders className="w-3.5 h-3.5" />
            <span>Screen 2: Route & Energy Optimizer</span>
            {executed && (
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span>
            )}
          </button>
        </nav>

        {/* Right indicators & Mobile Menu Trigger */}
        <div className="flex items-center gap-2">
          {/* Grid Rate badge */}
          <div className="hidden lg:flex items-center gap-1.5 bg-[#121417] px-2.5 py-1 rounded-lg border border-[#2A2E35] text-xs">
            <Zap className="w-3.5 h-3.5 text-[#00ADB5]" />
            <span className="text-[#8C93A0]">Depot Tariff:</span>
            <span className="font-mono-data text-white font-bold">
              ${gridPriceSurge.toFixed(2)}/kWh
            </span>
          </div>

          {/* Clock */}
          <div className="hidden sm:flex items-center gap-1.5 bg-[#121417] px-2.5 py-1 rounded-lg border border-[#2A2E35] text-xs font-mono-data text-[#A3ADC0]">
            <Clock className="w-3.5 h-3.5 text-[#6B7280]" />
            <span>{timeStr || '14:28:00 BST'}</span>
          </div>

          {/* Mobile Menu Hamburger (Mobile-First / Smartphone support) */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle Mobile Navigation Drawer"
            className="md:hidden p-2 rounded-lg bg-[#242932] text-white border border-[#2A2E35] hover:bg-[#2C323D] transition-colors"
          >
            {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer (Constraint 3: Mobile-Responsive Viewport) */}
      {mobileMenuOpen && (
        <div className="md:hidden bg-[#181B20] border-t-2 border-[#2A2E35] px-4 py-4 space-y-3 shadow-2xl">
          <div className="grid grid-cols-2 gap-2">
            <button
              onClick={() => {
                onSelectScreen('dispatch');
                setMobileMenuOpen(false);
              }}
              className={`p-3 rounded-xl text-left border-2 font-bold text-xs flex flex-col gap-1 ${
                currentScreen === 'dispatch'
                  ? 'bg-[#00ADB5] text-[#121417] border-[#00ADB5]'
                  : 'bg-[#14171C] text-white border-[#2A2E35]'
              }`}
            >
              <div className="flex items-center gap-1.5">
                <MapPin className="w-4 h-4" />
                <span>Screen 1</span>
              </div>
              <span className="text-[10px] opacity-80 font-normal">Live Dispatch Control</span>
            </button>

            <button
              onClick={() => {
                onSelectScreen('optimizer');
                setMobileMenuOpen(false);
              }}
              className={`p-3 rounded-xl text-left border-2 font-bold text-xs flex flex-col gap-1 ${
                currentScreen === 'optimizer'
                  ? 'bg-[#00ADB5] text-[#121417] border-[#00ADB5]'
                  : 'bg-[#14171C] text-white border-[#2A2E35]'
              }`}
            >
              <div className="flex items-center gap-1.5">
                <Sliders className="w-4 h-4" />
                <span>Screen 2</span>
              </div>
              <span className="text-[10px] opacity-80 font-normal">Route & Energy Optimizer</span>
            </button>
          </div>

          <div className="pt-2 border-t border-[#2A2E35] flex flex-col gap-2 text-xs">
            <button
              onClick={() => {
                onOpenPricing();
                setMobileMenuOpen(false);
              }}
              className="p-2.5 bg-[#121417] text-white border border-[#2A2E35] rounded-lg flex items-center justify-between font-medium"
            >
              <div className="flex items-center gap-2">
                <CreditCard className="w-4 h-4 text-[#00ADB5]" />
                <span>Plans & Transparent Pricing</span>
              </div>
              <span className="text-[10px] text-[#00ADB5] font-mono-data">$149 - $499/mo</span>
            </button>

            <button
              onClick={() => {
                onOpenDataLineage();
                setMobileMenuOpen(false);
              }}
              className="p-2.5 bg-[#121417] text-white border border-[#2A2E35] rounded-lg flex items-center justify-between font-medium"
            >
              <div className="flex items-center gap-2">
                <Database className="w-4 h-4 text-[#00ADB5]" />
                <span>Telemetry Data Lineage</span>
              </div>
              <span className="text-[10px] text-emerald-400 font-mono-data">6 Verified Sources</span>
            </button>

            <button
              onClick={() => {
                onOpenRShiny();
                setMobileMenuOpen(false);
              }}
              className="p-2.5 bg-[#121417] text-white border border-[#2A2E35] rounded-lg flex items-center justify-between font-medium"
            >
              <div className="flex items-center gap-2">
                <FileCode2 className="w-4 h-4 text-[#00ADB5]" />
                <span>Export Single-File app.R</span>
              </div>
              <span className="text-[10px] text-[#8C93A0] font-mono-data">R Shiny</span>
            </button>

            <button
              onClick={() => {
                onOpenDeleteAccount();
                setMobileMenuOpen(false);
              }}
              className="p-2.5 bg-rose-950/40 text-rose-300 border border-rose-500/60 rounded-lg flex items-center justify-between font-bold"
            >
              <div className="flex items-center gap-2">
                <ShieldAlert className="w-4 h-4 text-rose-400" />
                <span>GDPR Erasure (Guarded)</span>
              </div>
              <span className="text-[10px] font-mono-data bg-rose-900/60 px-1.5 py-0.5 rounded text-rose-200">
                Triple-Guard
              </span>
            </button>
          </div>
        </div>
      )}
    </header>
  );
};
