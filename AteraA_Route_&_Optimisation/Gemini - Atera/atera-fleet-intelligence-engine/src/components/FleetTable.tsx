import React, { useState, useMemo, useRef, useEffect } from 'react';
import { VehicleTelemetry, VehicleType, VehicleStatus } from '../types';
import { 
  Battery, 
  Clock, 
  Navigation, 
  CheckCircle, 
  AlertTriangle, 
  Search, 
  Filter, 
  ChevronLeft, 
  ChevronRight, 
  ChevronsLeft, 
  ChevronsRight, 
  ArrowUpDown, 
  ArrowUp, 
  ArrowDown, 
  X,
  Gauge,
  Radio
} from 'lucide-react';

interface FleetTableProps {
  fleet: VehicleTelemetry[];
  selectedVehicleId: string | null;
  onSelectVehicle: (id: string) => void;
  onOpenDataLineage?: () => void;
}

export const FleetTable: React.FC<FleetTableProps> = ({
  fleet,
  selectedVehicleId,
  onSelectVehicle,
  onOpenDataLineage,
}) => {
  // Search & Filter State
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [batteryFilter, setBatteryFilter] = useState<'all' | 'critical' | 'mid' | 'high'>('all');

  // Sorting
  const [sortField, setSortField] = useState<'vehicle_id' | 'battery_pct' | 'driver_hours_left' | 'speed_mph' | 'type'>('vehicle_id');
  const [sortAsc, setSortAsc] = useState<boolean>(true);

  // Pagination
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [pageSize, setPageSize] = useState<number>(10);
  const [jumpPageInput, setJumpPageInput] = useState<string>('');

  const searchInputRef = useRef<HTMLInputElement>(null);

  // Reset page when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, typeFilter, statusFilter, batteryFilter, pageSize]);

  // Filtering & Sorting with memoization for 10,000+ items
  const filteredAndSorted = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();

    return fleet
      .filter((v) => {
        // Text search
        if (query) {
          const matchId = v.vehicle_id.toLowerCase().includes(query);
          const matchDriver = v.driver_name.toLowerCase().includes(query);
          const matchDest = v.destination.toLowerCase().includes(query);
          const matchVin = v.vin ? v.vin.toLowerCase().includes(query) : false;
          if (!matchId && !matchDriver && !matchDest && !matchVin) return false;
        }

        // Type filter
        if (typeFilter !== 'all' && v.type !== typeFilter) return false;

        // Status filter
        if (statusFilter !== 'all') {
          if (statusFilter === 'Delayed' && !v.status.includes('Delayed')) return false;
          if (statusFilter === 'Charging' && !v.status.includes('Charging')) return false;
          if (statusFilter === 'Optimized' && !v.status.includes('OPTIMIZED') && !v.status.includes('REROUTED')) return false;
          if (statusFilter === 'On Route' && v.status !== 'On Route') return false;
        }

        // Battery filter
        if (batteryFilter === 'critical' && v.battery_pct > 20) return false;
        if (batteryFilter === 'mid' && (v.battery_pct <= 20 || v.battery_pct > 50)) return false;
        if (batteryFilter === 'high' && v.battery_pct <= 50) return false;

        return true;
      })
      .sort((a, b) => {
        let valA: any = a[sortField];
        let valB: any = b[sortField];

        if (typeof valA === 'string') {
          valA = valA.toLowerCase();
          valB = valB.toLowerCase();
        }

        if (valA < valB) return sortAsc ? -1 : 1;
        if (valA > valB) return sortAsc ? 1 : -1;
        return 0;
      });
  }, [fleet, searchQuery, typeFilter, statusFilter, batteryFilter, sortField, sortAsc]);

  const totalRecords = filteredAndSorted.length;
  const totalPages = Math.max(1, Math.ceil(totalRecords / pageSize));

  // Current page records
  const paginatedRecords = useMemo(() => {
    const startIndex = (currentPage - 1) * pageSize;
    return filteredAndSorted.slice(startIndex, startIndex + pageSize);
  }, [filteredAndSorted, currentPage, pageSize]);

  // Handle Sort column click
  const handleSort = (field: typeof sortField) => {
    if (sortField === field) {
      setSortAsc(!sortAsc);
    } else {
      setSortField(field);
      setSortAsc(true);
    }
  };

  // Keyboard navigation on table rows
  const handleRowKeyDown = (e: React.KeyboardEvent, vehicleId: string, index: number) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onSelectVehicle(vehicleId);
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      const nextIdx = Math.min(paginatedRecords.length - 1, index + 1);
      const nextRow = document.getElementById(`fleet-row-${nextIdx}`);
      nextRow?.focus();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      const prevIdx = Math.max(0, index - 1);
      const prevRow = document.getElementById(`fleet-row-${prevIdx}`);
      prevRow?.focus();
    }
  };

  const handleJumpToPage = (e: React.FormEvent) => {
    e.preventDefault();
    const p = parseInt(jumpPageInput, 10);
    if (!isNaN(p) && p >= 1 && p <= totalPages) {
      setCurrentPage(p);
      setJumpPageInput('');
    }
  };

  const selectedVehicle = fleet.find((v) => v.vehicle_id === selectedVehicleId) || paginatedRecords[0];

  const getStatusBadge = (status: string) => {
    if (status.includes('Charging')) {
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold bg-[#00ADB5]/20 text-[#00ADB5] border border-[#00ADB5]/40 font-mono-data">
          <span className="w-1.5 h-1.5 rounded-full bg-[#00ADB5] animate-pulse"></span>
          {status}
        </span>
      );
    }
    if (status.includes('Delayed')) {
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold bg-[#FF2E63]/25 text-[#FF2E63] border border-[#FF2E63]/50 animate-pulse font-mono-data">
          <AlertTriangle className="w-3 h-3 shrink-0" />
          {status}
        </span>
      );
    }
    if (status.includes('REROUTED') || status.includes('OPTIMIZED')) {
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-950/60 text-emerald-300 border border-emerald-700 font-mono-data">
          <CheckCircle className="w-3 h-3 shrink-0" />
          {status}
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-medium bg-[#242932] text-amber-400 border border-amber-900/60 font-mono-data">
        <Navigation className="w-3 h-3 shrink-0" />
        {status}
      </span>
    );
  };

  const getBatteryColor = (pct: number) => {
    if (pct <= 20) return 'text-[#FF2E63]';
    if (pct <= 40) return 'text-amber-400';
    return 'text-[#00ADB5]';
  };

  return (
    <div 
      className="bg-[#181B20] border-2 border-[#2A2E35] rounded-xl overflow-hidden shadow-md flex flex-col h-full"
      role="region"
      aria-label="Commercial Fleet Telemetry Registry (10,000+ Scale)"
    >
      {/* Table Header & Search Controls */}
      <div className="p-3 sm:p-4 border-b-2 border-[#2A2E35] bg-[#1C2026] space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <div className="w-2.5 h-2.5 rounded-full bg-[#00ADB5] ring-4 ring-[#00ADB5]/20"></div>
            <div>
              <h3 className="text-xs font-bold text-white uppercase tracking-wider">
                Vehicle Telemetry Roster
              </h3>
              <p className="text-[10px] text-[#8C93A0]">
                Scaled for 10,000+ assets with instant multi-filtering & keyboard control
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-[11px] text-white font-mono-data font-bold bg-[#121417] px-2.5 py-1 rounded border border-[#2E3540]">
              {totalRecords.toLocaleString()} / {fleet.length.toLocaleString()} Assets
            </span>
          </div>
        </div>

        {/* Dynamic Search & Multi-Filters */}
        <div className="grid grid-cols-1 sm:grid-cols-12 gap-2 text-xs">
          {/* Search box */}
          <div className="sm:col-span-5 relative">
            <Search className="w-3.5 h-3.5 text-[#8C93A0] absolute left-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              ref={searchInputRef}
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search 10,000+ by ID, driver, destination..."
              aria-label="Search vehicle telemetry database"
              className="w-full pl-8 pr-7 py-1.5 bg-[#121417] border-2 border-[#2A2E35] focus:border-[#00ADB5] rounded-lg text-white placeholder-[#6B7280] text-xs transition-colors focus-visible:ring-2 focus-visible:ring-[#00ADB5] outline-none"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                aria-label="Clear search input"
                className="absolute right-2 top-1/2 -translate-y-1/2 text-[#8C93A0] hover:text-white"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>

          {/* Type Filter */}
          <div className="sm:col-span-3">
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              aria-label="Filter by Vehicle Type"
              className="w-full py-1.5 px-2 bg-[#121417] border-2 border-[#2A2E35] focus:border-[#00ADB5] rounded-lg text-[#C5CDD9] text-xs transition-colors focus-visible:ring-2 focus-visible:ring-[#00ADB5] outline-none cursor-pointer"
            >
              <option value="all">Type: All Assets</option>
              <option value="Last-Mile EV">Last-Mile EV</option>
              <option value="Regional Freight">Regional Freight</option>
              <option value="Urban Delivery Van">Urban Delivery Van</option>
              <option value="Heavy EV Hauler">Heavy EV Hauler</option>
            </select>
          </div>

          {/* Status Filter */}
          <div className="sm:col-span-2">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              aria-label="Filter by Status"
              className="w-full py-1.5 px-2 bg-[#121417] border-2 border-[#2A2E35] focus:border-[#00ADB5] rounded-lg text-[#C5CDD9] text-xs transition-colors focus-visible:ring-2 focus-visible:ring-[#00ADB5] outline-none cursor-pointer"
            >
              <option value="all">Status: All</option>
              <option value="On Route">On Route</option>
              <option value="Delayed">Delayed</option>
              <option value="Charging">Charging</option>
              <option value="Optimized">Optimized</option>
            </select>
          </div>

          {/* Battery Health Filter */}
          <div className="sm:col-span-2">
            <select
              value={batteryFilter}
              onChange={(e) => setBatteryFilter(e.target.value as any)}
              aria-label="Filter by Battery SOC"
              className="w-full py-1.5 px-2 bg-[#121417] border-2 border-[#2A2E35] focus:border-[#00ADB5] rounded-lg text-[#C5CDD9] text-xs transition-colors focus-visible:ring-2 focus-visible:ring-[#00ADB5] outline-none cursor-pointer"
            >
              <option value="all">SoC: All</option>
              <option value="critical">Critical (&le;20%)</option>
              <option value="mid">Mid (21-50%)</option>
              <option value="high">High (&gt;50%)</option>
            </select>
          </div>
        </div>
      </div>

      {/* Accessible Table Container */}
      <div className="overflow-x-auto flex-1 min-h-[340px]">
        <table 
          className="w-full text-left text-xs border-collapse"
          role="grid"
          aria-rowcount={totalRecords}
        >
          <thead>
            <tr className="border-b-2 border-[#2A2E35] bg-[#14171C] text-[#8C93A0] text-[11px] uppercase tracking-wider font-mono-data">
              <th scope="col" className="py-2.5 px-3">
                <button
                  onClick={() => handleSort('vehicle_id')}
                  className="flex items-center gap-1 hover:text-white font-bold focus:outline-none focus:text-[#00ADB5]"
                >
                  <span>Vehicle ID</span>
                  {sortField === 'vehicle_id' ? (
                    sortAsc ? <ArrowUp className="w-3 h-3 text-[#00ADB5]" /> : <ArrowDown className="w-3 h-3 text-[#00ADB5]" />
                  ) : (
                    <ArrowUpDown className="w-3 h-3 opacity-40" />
                  )}
                </button>
              </th>
              <th scope="col" className="py-2.5 px-3">
                <button
                  onClick={() => handleSort('type')}
                  className="flex items-center gap-1 hover:text-white font-bold focus:outline-none focus:text-[#00ADB5]"
                >
                  <span>Asset Type</span>
                  {sortField === 'type' ? (
                    sortAsc ? <ArrowUp className="w-3 h-3 text-[#00ADB5]" /> : <ArrowDown className="w-3 h-3 text-[#00ADB5]" />
                  ) : (
                    <ArrowUpDown className="w-3 h-3 opacity-40" />
                  )}
                </button>
              </th>
              <th scope="col" className="py-2.5 px-3">Status</th>
              <th scope="col" className="py-2.5 px-3 text-right">
                <button
                  onClick={() => handleSort('battery_pct')}
                  className="flex items-center justify-end gap-1 hover:text-white font-bold focus:outline-none focus:text-[#00ADB5] ml-auto"
                >
                  <span>Battery (SoC)</span>
                  {sortField === 'battery_pct' ? (
                    sortAsc ? <ArrowUp className="w-3 h-3 text-[#00ADB5]" /> : <ArrowDown className="w-3 h-3 text-[#00ADB5]" />
                  ) : (
                    <ArrowUpDown className="w-3 h-3 opacity-40" />
                  )}
                </button>
              </th>
              <th scope="col" className="py-2.5 px-3 text-right">
                <button
                  onClick={() => handleSort('driver_hours_left')}
                  className="flex items-center justify-end gap-1 hover:text-white font-bold focus:outline-none focus:text-[#00ADB5] ml-auto"
                >
                  <span>Driver Hours</span>
                  {sortField === 'driver_hours_left' ? (
                    sortAsc ? <ArrowUp className="w-3 h-3 text-[#00ADB5]" /> : <ArrowDown className="w-3 h-3 text-[#00ADB5]" />
                  ) : (
                    <ArrowUpDown className="w-3 h-3 opacity-40" />
                  )}
                </button>
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#242932]">
            {paginatedRecords.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-8 text-center text-[#8C93A0] font-mono-data">
                  No vehicles matching search query or filters.
                </td>
              </tr>
            ) : (
              paginatedRecords.map((vehicle, idx) => {
                const isSelected = selectedVehicleId === vehicle.vehicle_id;

                return (
                  <tr
                    key={vehicle.vehicle_id}
                    id={`fleet-row-${idx}`}
                    tabIndex={0}
                    role="row"
                    aria-selected={isSelected}
                    onClick={() => onSelectVehicle(vehicle.vehicle_id)}
                    onKeyDown={(e) => handleRowKeyDown(e, vehicle.vehicle_id, idx)}
                    className={`cursor-pointer transition-all border-l-4 focus:outline-none focus:ring-2 focus:ring-[#00ADB5] ${
                      isSelected
                        ? 'bg-[#00ADB5]/15 border-l-[#00ADB5] text-white'
                        : 'border-l-transparent hover:bg-[#20252D] text-[#E0E0E0]'
                    }`}
                  >
                    {/* Vehicle ID & Driver */}
                    <td className="py-2.5 px-3">
                      <div className="font-mono-data font-bold text-white text-xs flex items-center gap-1.5">
                        <span>{vehicle.vehicle_id}</span>
                        {vehicle.depot && (
                          <span className="text-[9px] text-[#8C93A0] font-normal hidden lg:inline">
                            [{vehicle.depot.split(' ')[0]}]
                          </span>
                        )}
                      </div>
                      <div className="text-[10px] text-[#8C93A0] truncate max-w-[130px]">
                        {vehicle.driver_name}
                      </div>
                    </td>

                    {/* Type & Destination */}
                    <td className="py-2.5 px-3">
                      <span className="font-medium text-[11px] text-[#C5CDD9] block">
                        {vehicle.type}
                      </span>
                      <span className="text-[10px] text-[#6B7280] truncate max-w-[140px] block">
                        {vehicle.destination}
                      </span>
                    </td>

                    {/* Status badge */}
                    <td className="py-2.5 px-3">
                      {getStatusBadge(vehicle.status)}
                    </td>

                    {/* Battery */}
                    <td className="py-2.5 px-3 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <div className="w-10 bg-[#121417] h-1.5 rounded-full overflow-hidden border border-[#2E3540]">
                          <div
                            className={`h-full ${
                              vehicle.battery_pct <= 20
                                ? 'bg-[#FF2E63]'
                                : vehicle.battery_pct <= 40
                                ? 'bg-amber-400'
                                : 'bg-[#00ADB5]'
                            }`}
                            style={{ width: `${vehicle.battery_pct}%` }}
                          />
                        </div>
                        <span
                          className={`font-mono-data font-bold text-xs ${getBatteryColor(
                            vehicle.battery_pct
                          )}`}
                        >
                          {vehicle.battery_pct}%
                        </span>
                      </div>
                    </td>

                    {/* Driver Hours Left */}
                    <td className="py-2.5 px-3 text-right">
                      <span className="font-mono-data text-white font-bold text-xs">
                        {vehicle.driver_hours_left.toFixed(1)}h
                      </span>
                      <div className="text-[10px] text-[#6B7280]">
                        {vehicle.driver_hours_left < 3.0 ? (
                          <span className="text-amber-400 font-semibold">Near Limit</span>
                        ) : (
                          'Legal'
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination Bar (Keyboard Accessible) */}
      <div className="px-3 py-2.5 bg-[#14171C] border-t-2 border-[#2A2E35] flex flex-wrap items-center justify-between gap-2 text-xs">
        {/* Page size & Status */}
        <div className="flex items-center gap-2">
          <span className="text-[11px] text-[#8C93A0] font-mono-data">
            Page {currentPage} of {totalPages}
          </span>
          <select
            value={pageSize}
            onChange={(e) => setPageSize(Number(e.target.value))}
            aria-label="Rows per page"
            className="py-1 px-1.5 bg-[#181B20] border border-[#2A2E35] rounded text-white text-[11px] focus:ring-1 focus:ring-[#00ADB5]"
          >
            <option value={10}>10 / page</option>
            <option value={25}>25 / page</option>
            <option value={50}>50 / page</option>
            <option value={100}>100 / page</option>
          </select>
        </div>

        {/* Navigation Buttons */}
        <div className="flex items-center gap-1">
          <button
            onClick={() => setCurrentPage(1)}
            disabled={currentPage === 1}
            aria-label="Go to first page"
            className="p-1.5 rounded bg-[#181B20] hover:bg-[#242932] disabled:opacity-30 border border-[#2A2E35] text-white disabled:pointer-events-none transition-colors"
          >
            <ChevronsLeft className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
            disabled={currentPage === 1}
            aria-label="Go to previous page"
            className="p-1.5 rounded bg-[#181B20] hover:bg-[#242932] disabled:opacity-30 border border-[#2A2E35] text-white disabled:pointer-events-none transition-colors"
          >
            <ChevronLeft className="w-3.5 h-3.5" />
          </button>

          {/* Jump to page direct form */}
          <form onSubmit={handleJumpToPage} className="flex items-center gap-1 px-1">
            <input
              type="text"
              value={jumpPageInput}
              onChange={(e) => setJumpPageInput(e.target.value)}
              placeholder={`${currentPage}`}
              aria-label="Jump to specific page number"
              className="w-10 text-center py-0.5 bg-[#121417] border border-[#2A2E35] rounded text-white font-mono-data text-[11px]"
            />
          </form>

          <button
            onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
            disabled={currentPage === totalPages}
            aria-label="Go to next page"
            className="p-1.5 rounded bg-[#181B20] hover:bg-[#242932] disabled:opacity-30 border border-[#2A2E35] text-white disabled:pointer-events-none transition-colors"
          >
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={() => setCurrentPage(totalPages)}
            disabled={currentPage === totalPages}
            aria-label="Go to last page"
            className="p-1.5 rounded bg-[#181B20] hover:bg-[#242932] disabled:opacity-30 border border-[#2A2E35] text-white disabled:pointer-events-none transition-colors"
          >
            <ChevronsRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Selected Vehicle Quick Telemetry Inspector (with Data Provenance tag) */}
      {selectedVehicle && (
        <div className="p-3 bg-[#121417] border-t-2 border-[#2A2E35] text-xs">
          <div className="flex flex-wrap items-center justify-between gap-1 mb-2">
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
              <span className="text-[11px] text-white font-bold font-mono-data">
                NODE: {selectedVehicle.vehicle_id}
              </span>
              <span className="text-[10px] text-[#8C93A0]">
                ({selectedVehicle.type})
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-[10px] text-[#00ADB5] font-mono-data">
                GPS: {selectedVehicle.lat.toFixed(4)}, {selectedVehicle.lng.toFixed(4)}
              </span>
              {onOpenDataLineage && (
                <button
                  onClick={onOpenDataLineage}
                  className="text-[9px] bg-[#1C2026] text-[#8C93A0] hover:text-[#00ADB5] px-1.5 py-0.5 rounded border border-[#2E3540] transition-colors"
                >
                  Lineage Tag
                </button>
              )}
            </div>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-[11px] bg-[#181B20] p-2 rounded-lg border border-[#242932]">
            <div>
              <span className="text-[#8C93A0] block text-[9px] uppercase font-mono-data">Speed / Heading</span>
              <span className="font-mono-data font-bold text-white">
                {selectedVehicle.speed_mph} mph • {selectedVehicle.heading}&deg;
              </span>
            </div>
            <div>
              <span className="text-[#8C93A0] block text-[9px] uppercase font-mono-data">Assigned Driver</span>
              <span className="font-medium text-white truncate block">
                {selectedVehicle.driver_name}
              </span>
            </div>
            <div>
              <span className="text-[#8C93A0] block text-[9px] uppercase font-mono-data">Home Depot</span>
              <span className="font-medium text-white truncate block">
                {selectedVehicle.depot || 'Depot B (Central)'}
              </span>
            </div>
            <div>
              <span className="text-[#8C93A0] block text-[9px] uppercase font-mono-data">VIN / CAN Stream</span>
              <span className="font-mono-data text-emerald-400 truncate block text-[10px]">
                {selectedVehicle.vin || '1FT-CAN-88912'}
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
