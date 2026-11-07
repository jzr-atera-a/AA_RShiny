import React, { useState, useMemo } from 'react';
import { Navbar } from './components/Navbar';
import { DispatchConsole } from './components/DispatchConsole';
import { KpiBar } from './components/KpiBar';
import { DispatchMap } from './components/DispatchMap';
import { FleetTable } from './components/FleetTable';
import { RouteOptimizerMap } from './components/RouteOptimizerMap';
import { ChargingSchedulePlot } from './components/ChargingSchedulePlot';
import { PricingModal } from './components/PricingModal';
import { DeleteAccountModal } from './components/DeleteAccountModal';
import { DataLineageModal } from './components/DataLineageModal';
import { RShinyModal } from './components/RShinyModal';
import { FailureReceiptModal } from './components/FailureReceiptModal';
import { 
  initialFleet, 
  cached10kFleet,
  routeOrig, 
  routeOptStandard, 
  routeOptStormBypass, 
  getChargingSchedule, 
  computeScenarioMetrics 
} from './data/fleetData';
import { VehicleTelemetry, RoutePoint, PricingTierId } from './types';
import { CheckCircle2, Sliders, MapPin, ArrowRight, ShieldCheck, Database, FileCode2 } from 'lucide-react';

export default function App() {
  // Screen navigation state ('dispatch' = Screen 1, 'optimizer' = Screen 2)
  const [currentScreen, setCurrentScreen] = useState<'dispatch' | 'optimizer'>('dispatch');

  // Environmental inputs
  const [simStorm, setSimStorm] = useState<boolean>(false);
  const [gridPriceSurge, setGridPriceSurge] = useState<number>(0.18);

  // Map layer visibility
  const [showTraffic, setShowTraffic] = useState<boolean>(true);
  const [showWeatherOverlay, setShowWeatherOverlay] = useState<boolean>(true);

  // Selected vehicle for inspector
  const [selectedVehicleId, setSelectedVehicleId] = useState<string | null>('VAN-102');

  // Reactive State Manager
  const [executed, setExecuted] = useState<boolean>(false);
  const [executedAt, setExecutedAt] = useState<string | null>(null);
  const [activeRoute, setActiveRoute] = useState<RoutePoint[]>(routeOptStandard);
  const [activeFleet, setActiveFleet] = useState<VehicleTelemetry[]>(initialFleet);
  const [statusMsg, setStatusMsg] = useState<string>(
    "Standing by. Click 'Execute Reroute Queue' to optimize."
  );

  // 10,000+ Mock Records for Fleet Table Scale (Constraint 6)
  const [largeFleet, setLargeFleet] = useState<VehicleTelemetry[]>(cached10kFleet);

  // The Six Constraints Modals & Accessibility States
  const [isPricingOpen, setIsPricingOpen] = useState<boolean>(false);
  const [isDeleteAccountOpen, setIsDeleteAccountOpen] = useState<boolean>(false);
  const [isDataLineageOpen, setIsDataLineageOpen] = useState<boolean>(false);
  const [isRShinyOpen, setIsRShinyOpen] = useState<boolean>(false);
  const [isFailureReceiptOpen, setIsFailureReceiptOpen] = useState<boolean>(false);
  const [activeTier, setActiveTier] = useState<PricingTierId>('enterprise');
  const [highContrast, setHighContrast] = useState<boolean>(false);

  // Notification toast
  const [toastMsg, setToastMsg] = useState<string | null>(null);

  // Chaos / Injected Failure Mode: Demonstrates the called contradiction
  const handleApplyChaosMode = () => {
    setSimStorm(true);
    setExecuted(true);
    setExecutedAt('14:32:00 BST');
    setActiveRoute(routeOptStormBypass);
    setGridPriceSurge(0.60);

    const brokenFleet: VehicleTelemetry[] = initialFleet.map((v) => ({ ...v }));
    brokenFleet[1] = {
      ...brokenFleet[1],
      status: 'STRANDED: Waterlogged in Zone B (Motor Lock)',
      speed_mph: 0,
      battery_pct: 12,
      lat: 51.5200,
      lng: -0.0900,
    };
    setActiveFleet(brokenFleet);
    setSelectedVehicleId('VAN-102');
    setStatusMsg('CRITICAL ERROR: Software claims 100% bypass while VAN-102 is stranded in Zone B flood. Depot draw exceeds transformer limits.');
    setToastMsg('FAILURE MODE INJECTED: 2 Fatal Contradictions Active');
  };

  // Trigger Execution Pipeline across BOTH screens
  const handleExecuteReroute = () => {
    const now = new Date();
    const timestamp = now.toLocaleTimeString('en-GB', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      timeZone: 'Europe/London',
    });

    setExecuted(true);
    setExecutedAt(timestamp);

    // Deep clone initial fleet
    const updatedFleet: VehicleTelemetry[] = initialFleet.map((v) => ({ ...v }));

    if (simStorm) {
      updatedFleet[1].status = 'REROUTED (Bypassing Storm)'; // VAN-102
      updatedFleet[0].status = 'OPTIMIZED (Energy Efficient)'; // VAN-101
      setActiveRoute(routeOptStormBypass);
      setStatusMsg(`SUCCESS: Storm bypass path deployed at ${timestamp}`);
    } else {
      updatedFleet[1].status = 'OPTIMIZED (Standard)';
      setActiveRoute(routeOptStandard);
      setStatusMsg(`SUCCESS: Dynamic reroute deployed at ${timestamp}`);
    }

    setActiveFleet(updatedFleet);

    // Also reflect optimization in the 10k table records
    setLargeFleet((prev) =>
      prev.map((v) => {
        if (v.vehicle_id === 'VAN-102') {
          return { ...v, status: simStorm ? 'REROUTED (Bypassing Storm)' : 'OPTIMIZED (Standard)' };
        }
        if (v.vehicle_id === 'VAN-101') {
          return { ...v, status: 'OPTIMIZED (Energy Efficient)' };
        }
        return v;
      })
    );

    // Show notification toast
    setToastMsg('Fleet Reroute & Charge Schedule Executed!');
    setTimeout(() => {
      setToastMsg(null);
    }, 4500);
  };

  // Reactively clear/update execution state if environmental parameters change
  const handleToggleStorm = (val: boolean) => {
    setSimStorm(val);
    if (executed) {
      setStatusMsg("Parameters changed. Re-click 'Execute Reroute Queue'.");
    }
  };

  const handleChangeGridPrice = (val: number) => {
    setGridPriceSurge(val);
    if (executed) {
      setStatusMsg("Parameters changed. Re-click 'Execute Reroute Queue'.");
    }
  };

  const handleResetSimulation = () => {
    setExecuted(false);
    setExecutedAt(null);
    setSimStorm(false);
    setGridPriceSurge(0.18);
    setActiveFleet(initialFleet);
    setLargeFleet(cached10kFleet);
    setActiveRoute(routeOptStandard);
    setStatusMsg("Standing by. Click 'Execute Reroute Queue' to optimize.");
    setToastMsg('Simulation reset to nominal baseline state.');
    setTimeout(() => setToastMsg(null), 3000);
  };

  // 1-Click Delete Account & Wipe Data (Constraint 1: Regulation)
  const handleWipeData = () => {
    setExecuted(false);
    setExecutedAt(null);
    setSimStorm(false);
    setGridPriceSurge(0.18);
    setActiveFleet(initialFleet);
    setLargeFleet(cached10kFleet);
    setActiveRoute(routeOptStandard);
    setStatusMsg("Account telemetry wiped. Standing by for fresh telemetry ingest.");
    setToastMsg('Account & CAN-bus data permanently erased under GDPR Art. 17.');
    setTimeout(() => setToastMsg(null), 5000);
  };

  // Select a vehicle from anywhere
  const handleSelectVehicle = (id: string) => {
    setSelectedVehicleId(id);
    const target = initialFleet.find((v) => v.vehicle_id === id);
    if (target) {
      setToastMsg(`Inspecting telemetry for asset ${id} (${target.driver_name})`);
      setTimeout(() => setToastMsg(null), 2500);
    }
  };

  // Compute charging plot data and metrics reactively
  const chargingData = useMemo(() => {
    return getChargingSchedule(executed, gridPriceSurge);
  }, [executed, gridPriceSurge]);

  const metrics = useMemo(() => {
    return computeScenarioMetrics(executed, simStorm, gridPriceSurge);
  }, [executed, simStorm, gridPriceSurge]);

  return (
    <div className={`min-h-screen bg-[#121417] text-[#E0E0E0] flex flex-col font-sans ${
      highContrast ? 'contrast-125' : ''
    }`}>
      {/* Top Application Header / Navigation with Upfront Pricing & 1-Click Delete Account */}
      <Navbar
        currentScreen={currentScreen}
        onSelectScreen={setCurrentScreen}
        simStorm={simStorm}
        executed={executed}
        gridPriceSurge={gridPriceSurge}
        activeTier={activeTier}
        onOpenPricing={() => setIsPricingOpen(true)}
        onOpenDeleteAccount={() => setIsDeleteAccountOpen(true)}
        onOpenDataLineage={() => setIsDataLineageOpen(true)}
        onOpenRShiny={() => setIsRShinyOpen(true)}
        onOpenFailureReceipt={() => setIsFailureReceiptOpen(true)}
        highContrast={highContrast}
        onToggleHighContrast={() => setHighContrast(!highContrast)}
      />

      {/* Floating Alert / Notification Toast */}
      {toastMsg && (
        <div className="fixed top-16 right-4 z-50 animate-in fade-in slide-in-from-top-3 duration-300">
          <div className="bg-[#181B20] border-2 border-[#00ADB5] text-white px-4 py-3 rounded-lg shadow-2xl flex items-center gap-3">
            <CheckCircle2 className="w-5 h-5 text-[#00ADB5] shrink-0" />
            <span className="font-semibold text-xs tracking-wide">{toastMsg}</span>
          </div>
        </div>
      )}

      {/* Main Workspace (Constraint 3: Mobile-Responsive fluid layout) */}
      <main className="flex-1 p-3 sm:p-4 lg:p-6 w-full max-w-[1720px] mx-auto space-y-4">
        {/* ========================================================================= */}
        {/* SCREEN 1: Live Dispatch Control Center                                     */}
        {/* ========================================================================= */}
        {currentScreen === 'dispatch' && (
          <div className="flex flex-col lg:flex-row gap-4 items-start">
            {/* Sidebar: Dispatch Control Console (width 320px) */}
            <DispatchConsole
              simStorm={simStorm}
              onToggleStorm={handleToggleStorm}
              gridPriceSurge={gridPriceSurge}
              onChangeGridPrice={handleChangeGridPrice}
              onExecuteReroute={handleExecuteReroute}
              onResetSimulation={handleResetSimulation}
              executed={executed}
              executedAt={executedAt}
              statusMsg={statusMsg}
              showTraffic={showTraffic}
              onToggleTraffic={setShowTraffic}
              showWeatherOverlay={showWeatherOverlay}
              onToggleWeatherOverlay={setShowWeatherOverlay}
              onOpenDataLineage={() => setIsDataLineageOpen(true)}
              onOpenDeleteAccount={() => setIsDeleteAccountOpen(true)}
            />

            {/* Main Center & Right Column */}
            <div className="flex-1 w-full space-y-4">
              {/* Top Row: 4 Value Boxes (KPI Bar with explicit Data Lineage tags) */}
              <KpiBar
                fleet={largeFleet}
                simStorm={simStorm}
                executed={executed}
                gridPriceSurge={gridPriceSurge}
                onOpenDataLineage={() => setIsDataLineageOpen(true)}
              />

              {/* Middle Row: Live Map & 10,000 Scale Telemetry Table */}
              <div className="grid grid-cols-1 xl:grid-cols-12 gap-4 items-start">
                {/* Live Dispatch Map */}
                <div className="xl:col-span-7 2xl:col-span-8 flex flex-col">
                  <div className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl overflow-hidden shadow-md">
                    <div className="px-4 py-3 border-b-2 border-[#2A2E35] bg-[#1C2026] flex flex-wrap items-center justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <div className="p-1 rounded bg-[#00ADB5]/10 text-[#00ADB5] border border-[#00ADB5]/30">
                          <MapPin className="w-4 h-4" />
                        </div>
                        <div>
                          <h3 className="text-xs font-bold text-white uppercase tracking-wider">
                            Fleet Telemetry & Weather Overlay
                          </h3>
                          <span className="text-[10px] text-[#8C93A0]">
                            Real-time geospatial sensor tracking
                          </span>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 text-xs">
                        {simStorm && !executed && (
                          <span className="text-[#FF2E63] font-mono-data text-[11px] bg-[#FF2E63]/10 px-2 py-0.5 rounded border border-[#FF2E63]/30 animate-pulse">
                            VAN-102 Storm Impeded
                          </span>
                        )}
                        {simStorm && executed && (
                          <span className="text-emerald-400 font-mono-data text-[11px] bg-emerald-950/40 px-2 py-0.5 rounded border border-emerald-800">
                            Rerouted via Safe Corridor
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="p-3">
                      <DispatchMap
                        fleet={activeFleet}
                        simStorm={simStorm}
                        executed={executed}
                        selectedVehicleId={selectedVehicleId}
                        onSelectVehicle={handleSelectVehicle}
                        showTraffic={showTraffic}
                        showWeatherOverlay={showWeatherOverlay}
                      />
                    </div>
                  </div>
                </div>

                {/* Active Vehicle Roster Table (10,000+ Scale with Search & Pagination) */}
                <div className="xl:col-span-5 2xl:col-span-4 flex flex-col">
                  <FleetTable
                    fleet={largeFleet}
                    selectedVehicleId={selectedVehicleId}
                    onSelectVehicle={handleSelectVehicle}
                    onOpenDataLineage={() => setIsDataLineageOpen(true)}
                  />
                </div>
              </div>

              {/* Quick Jump Bar to Screen 2 */}
              <div className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl p-3 flex flex-wrap items-center justify-between gap-3 text-xs">
                <div className="flex items-center gap-2">
                  <Sliders className="w-4 h-4 text-[#00ADB5]" />
                  <span className="text-[#C5CDD9]">
                    Ready to evaluate corridor geometry and utility load shifting?
                  </span>
                </div>
                <button
                  id="btn-goto-optimizer"
                  onClick={() => setCurrentScreen('optimizer')}
                  className="bg-[#242932] hover:bg-[#2C323D] text-white px-3.5 py-2 rounded-lg flex items-center gap-2 transition-colors border-2 border-[#393E46] text-xs font-bold cursor-pointer"
                >
                  <span>Open Route & Energy Optimizer</span>
                  <ArrowRight className="w-3.5 h-3.5 text-[#00ADB5]" />
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* SCREEN 2: Route & Energy Optimizer                                         */}
        {/* ========================================================================= */}
        {currentScreen === 'optimizer' && (
          <div className="space-y-4">
            {/* Optimizer Scenario Control Strip */}
            <div className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl p-4 flex flex-wrap items-center justify-between gap-4">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-[#00ADB5]/15 border-2 border-[#00ADB5]/30 text-[#00ADB5]">
                  <Sliders className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-sm font-bold text-white uppercase tracking-wider">
                    Route & Energy Optimizer Dual-Pane Workspace
                  </h2>
                  <p className="text-[11px] text-[#8C93A0]">
                    Scenario simulation comparing original vs. AI-optimized routes and EV depot load profile
                  </p>
                </div>
              </div>

              {/* Live Parameters & Quick Execute */}
              <div className="flex flex-wrap items-center gap-3">
                <div className="bg-[#121417] px-3 py-1.5 rounded border border-[#2A2E35] text-xs flex items-center gap-2">
                  <span className="text-[#8C93A0]">Storm Alert:</span>
                  <span
                    className={`font-mono-data font-bold ${
                      simStorm ? 'text-amber-400' : 'text-gray-400'
                    }`}
                  >
                    {simStorm ? 'Zone B ACTIVE' : 'Clear'}
                  </span>
                </div>

                <div className="bg-[#121417] px-3 py-1.5 rounded border border-[#2A2E35] text-xs flex items-center gap-2">
                  <span className="text-[#8C93A0]">Depot Tariff:</span>
                  <span className="font-mono-data font-bold text-[#00ADB5]">
                    ${gridPriceSurge.toFixed(2)}/kWh
                  </span>
                </div>

                <button
                  id="optimizer-trigger-reroute"
                  onClick={handleExecuteReroute}
                  className="bg-[#00ADB5] hover:bg-[#009299] text-[#121417] font-extrabold text-xs uppercase px-4 py-2.5 rounded-lg transition-all shadow-md flex items-center gap-2 cursor-pointer border-2 border-[#00ADB5]"
                >
                  <CheckCircle2 className="w-4 h-4 fill-current" />
                  <span>Execute Reroute Queue</span>
                </button>
              </div>
            </div>

            {/* Dual-Pane Layout (6 col / 6 col) */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 items-stretch">
              {/* Left Pane: Route Optimizer Leaflet Map */}
              <RouteOptimizerMap
                activeRoute={activeRoute}
                executed={executed}
                executedAt={executedAt}
                simStorm={simStorm}
                metrics={metrics}
              />

              {/* Right Pane: Automated EV Depot Charging Schedule */}
              <ChargingSchedulePlot
                data={chargingData}
                executed={executed}
                gridPriceSurge={gridPriceSurge}
                metrics={metrics}
              />
            </div>

            {/* Bottom Technical Overview & Comparative Summary */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
              <div className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl p-3 text-xs">
                <span className="text-[10px] uppercase text-[#8C93A0] block font-mono-data">
                  Corridor Clearance
                </span>
                <span className="text-base font-bold text-white font-mono-data mt-1 block">
                  {simStorm
                    ? executed
                      ? '100% Storm Hazard Bypass'
                      : 'Severe Delay at Old St'
                    : 'Optimal Baseline'}
                </span>
                <p className="text-[11px] text-[#8C93A0] mt-1">
                  Bypasses Zone B arterial flood risks via Southwark connector
                </p>
              </div>

              <div className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl p-3 text-xs">
                <span className="text-[10px] uppercase text-[#8C93A0] block font-mono-data">
                  Transit Duration Saved
                </span>
                <span className="text-base font-bold text-emerald-400 font-mono-data mt-1 block">
                  -{metrics.durationSavedMin} Minutes
                </span>
                <p className="text-[11px] text-[#8C93A0] mt-1">
                  Avoids idling and gridlock along central distribution sector
                </p>
              </div>

              <div className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl p-3 text-xs">
                <span className="text-[10px] uppercase text-[#8C93A0] block font-mono-data">
                  Traction Energy Saved
                </span>
                <span className="text-base font-bold text-[#00ADB5] font-mono-data mt-1 block">
                  -{metrics.energySavedKWh} kWh
                </span>
                <p className="text-[11px] text-[#8C93A0] mt-1">
                  Reduces battery degradation through smoother speed profile
                </p>
              </div>

              <div className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl p-3 text-xs">
                <span className="text-[10px] uppercase text-[#8C93A0] block font-mono-data">
                  Daily Tariff Savings
                </span>
                <span className="text-base font-bold text-emerald-400 font-mono-data mt-1 block">
                  ${metrics.costSaved.toFixed(2)} / Day
                </span>
                <p className="text-[11px] text-[#8C93A0] mt-1">
                  Depot charges 00:00–04:00 at $0.10/kWh instead of peak rates
                </p>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t-2 border-[#2A2E35] bg-[#14171C] px-6 py-3 text-[11px] text-[#8C93A0] flex flex-wrap items-center justify-between gap-2 mt-auto">
        <div className="flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
          <span>Atera Fleet Intelligence Engine • Commercial Fleet Operations & EV Depot Dispatch</span>
        </div>
        <div className="flex items-center gap-3 font-mono-data text-[10px] text-[#8C93A0]">
          <button onClick={() => setIsDataLineageOpen(true)} className="hover:text-white flex items-center gap-1">
            <Database className="w-3 h-3 text-[#00ADB5]" /> Data Lineage
          </button>
          <span>•</span>
          <button onClick={() => setIsPricingOpen(true)} className="hover:text-white">
            Pricing ($149 - $499)
          </button>
          <span>•</span>
          <button onClick={() => setIsRShinyOpen(true)} className="hover:text-white flex items-center gap-1 text-[#00ADB5]">
            <FileCode2 className="w-3 h-3" /> app.R Spec
          </button>
          <span>•</span>
          <button onClick={() => setIsDeleteAccountOpen(true)} className="text-[#FF2E63] hover:underline">
            1-Click Delete
          </button>
        </div>
      </footer>

      {/* The Six Constraints Interactive Modals */}
      <PricingModal
        isOpen={isPricingOpen}
        onClose={() => setIsPricingOpen(false)}
        activeTier={activeTier}
        onSelectTier={(tier) => {
          setActiveTier(tier);
          setToastMsg(`Plan updated to ${tier.toUpperCase()}`);
          setTimeout(() => setToastMsg(null), 3000);
        }}
      />

      <DeleteAccountModal
        isOpen={isDeleteAccountOpen}
        onClose={() => setIsDeleteAccountOpen(false)}
        onConfirmDelete={handleWipeData}
      />

      <DataLineageModal
        isOpen={isDataLineageOpen}
        onClose={() => setIsDataLineageOpen(false)}
      />

      <RShinyModal
        isOpen={isRShinyOpen}
        onClose={() => setIsRShinyOpen(false)}
      />

      <FailureReceiptModal
        isOpen={isFailureReceiptOpen}
        onClose={() => setIsFailureReceiptOpen(false)}
        onApplyChaosMode={handleApplyChaosMode}
      />
    </div>
  );
}
