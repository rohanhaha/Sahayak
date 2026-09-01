import React, { useState, useEffect, useCallback } from 'react';
import { Booking, WorkerItem, PlatformKPIs } from './types';
import { fetchBookings, fetchWorkers } from './services/api';
import { KPICards } from './components/KPICards';
import { BookingsTable } from './components/BookingsTable';
import { WorkerVerification } from './components/WorkerVerification';
import { ShieldCheck, Activity, Users } from 'lucide-react';

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'DISPATCH' | 'WORKERS'>('DISPATCH');
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [workers, setWorkers] = useState<WorkerItem[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [tableFilter, setTableFilter] = useState<string>('ALL');

  const loadData = useCallback(async () => {
    setIsLoading(true);
    try {
      const [bookingsData, workersData] = await Promise.all([
        fetchBookings(),
        fetchWorkers(),
      ]);
      setBookings(bookingsData);
      setWorkers(workersData);
      setLastUpdated(new Date());
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
    // Auto-refresh every 8 seconds to reflect mobile phone bookings live
    const interval = setInterval(loadData, 8000);
    return () => clearInterval(interval);
  }, [loadData]);

  const handleKpiCardClick = (status: string) => {
    setActiveTab('DISPATCH');
    setTableFilter(status);
  };

  // Compute live KPIs
  const totalBookings = bookings.length;
  const pendingBookings = bookings.filter((b) => b.status === 'PENDING').length;
  const completedBookings = bookings.filter((b) => b.status === 'COMPLETED').length;
  const activeWorkers = workers.filter((w) => w.verification_status === 'VERIFIED').length;
  const totalEarningsPaise = bookings
    .filter((b) => b.status === 'COMPLETED')
    .reduce((acc, b) => acc + (b.services?.base_price_amount || 49900), 0);

  const kpis: PlatformKPIs = {
    totalBookings,
    pendingBookings,
    completedBookings,
    activeWorkers,
    totalEarningsPaise,
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col">
      {/* Top Navbar */}
      <header className="bg-white border-b border-slate-200 sticky top-0 z-30 shadow-xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-coop-primary flex items-center justify-center text-white shadow-sm">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-extrabold text-lg tracking-tight text-slate-900">
                  SAHAYAK
                </span>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-coop-50 text-coop-primary border border-coop-200 uppercase tracking-wide">
                  Cooperative Federation
                </span>
              </div>
              <p className="text-[11px] text-slate-500">
                Labour Federation Operations & Dispatch Command Center
              </p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            {/* Live Pulse Indicator */}
            <div className="hidden sm:flex items-center gap-2 text-xs text-slate-500 font-medium">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
              <span>Syncing with Cloud API</span>
              <span className="text-[10px] text-slate-400">
                ({lastUpdated.toLocaleTimeString()})
              </span>
            </div>

            {/* Federation Admin Avatar */}
            <div className="flex items-center gap-2 pl-4 border-l border-slate-200">
              <div className="w-8 h-8 rounded-full bg-slate-800 text-white flex items-center justify-center font-bold text-xs">
                FA
              </div>
              <div className="hidden md:block text-left">
                <div className="text-xs font-bold text-slate-800">Federation Admin</div>
                <div className="text-[10px] text-slate-400">Bengaluru Central Ward</div>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 flex-1 w-full">
        {/* Clickable KPI Banner */}
        <KPICards kpis={kpis} onFilterSelect={handleKpiCardClick} />

        {/* View Switcher Tabs */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2 border-b border-slate-200 w-full">
            <button
              onClick={() => setActiveTab('DISPATCH')}
              className={`flex items-center gap-2 py-3 px-4 text-xs font-bold border-b-2 transition-colors cursor-pointer ${
                activeTab === 'DISPATCH'
                  ? 'border-coop-primary text-coop-primary'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <Activity className="w-4 h-4" /> Live Booking Dispatch Monitor
              <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-slate-100 text-slate-700">
                {bookings.length}
              </span>
            </button>

            <button
              onClick={() => setActiveTab('WORKERS')}
              className={`flex items-center gap-2 py-3 px-4 text-xs font-bold border-b-2 transition-colors cursor-pointer ${
                activeTab === 'WORKERS'
                  ? 'border-coop-primary text-coop-primary'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <Users className="w-4 h-4" /> Worker Verification & Welfare Registry
              <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-slate-100 text-slate-700">
                {workers.length}
              </span>
            </button>
          </div>
        </div>

        {/* Active View Container */}
        {activeTab === 'DISPATCH' ? (
          <BookingsTable
            bookings={bookings}
            isLoading={isLoading}
            onRefresh={loadData}
            filterStatus={tableFilter}
            onFilterChange={setTableFilter}
          />
        ) : (
          <WorkerVerification
            workers={workers}
            onUpdate={loadData}
          />
        )}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-slate-200 py-4 mt-8 text-center text-xs text-slate-400">
        <p>
          Sahayak Cooperative Platform • Smart India Hackathon 2026 • Powered by FastAPI & Supabase
        </p>
      </footer>
    </div>
  );
};

export default App;
