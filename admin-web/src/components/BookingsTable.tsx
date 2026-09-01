import React, { useState } from 'react';
import { Booking, BookingStatus } from '../types';
import { Search, Filter, Clock, CheckCircle2, AlertCircle, RefreshCw } from 'lucide-react';

interface BookingsTableProps {
  bookings: Booking[];
  isLoading: boolean;
  onRefresh: () => void;
}

export const BookingsTable: React.FC<BookingsTableProps> = ({
  bookings,
  isLoading,
  onRefresh,
}) => {
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const filteredBookings = bookings.filter((b) => {
    const matchesStatus =
      filterStatus === 'ALL' ||
      (filterStatus === 'ACTIVE' && (b.status === 'ACCEPTED' || b.status === 'IN_PROGRESS')) ||
      b.status === filterStatus;

    const sQuery = searchQuery.toLowerCase();
    const serviceName = (b.services?.name || 'Service').toLowerCase();
    const customerName = (b.profiles?.full_name || 'Customer').toLowerCase();
    const address = (b.address || '').toLowerCase();

    const matchesSearch =
      sQuery === '' ||
      serviceName.includes(sQuery) ||
      customerName.includes(sQuery) ||
      address.includes(sQuery);

    return matchesStatus && matchesSearch;
  });

  const getStatusBadge = (status: BookingStatus) => {
    switch (status) {
      case 'PENDING':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
            <Clock className="w-3 h-3" /> Pending Dispatch
          </span>
        );
      case 'ACCEPTED':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200">
            <CheckCircle2 className="w-3 h-3" /> Worker Accepted
          </span>
        );
      case 'IN_PROGRESS':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-indigo-50 text-indigo-700 border border-indigo-200">
            <RefreshCw className="w-3 h-3 animate-spin" /> In Progress
          </span>
        );
      case 'COMPLETED':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
            <CheckCircle2 className="w-3 h-3" /> Completed
          </span>
        );
      case 'CANCELLED':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-50 text-rose-700 border border-rose-200">
            <AlertCircle className="w-3 h-3" /> Cancelled
          </span>
        );
      default:
        return <span className="text-xs text-slate-500">{status}</span>;
    }
  };

  const formatPrice = (paise?: number) => {
    if (!paise) return '₹499';
    return `₹${(paise / 100).toFixed(0)}`;
  };

  const formatDate = (isoString?: string) => {
    if (!isoString) return 'Today';
    try {
      const dt = new Date(isoString);
      return dt.toLocaleDateString('en-IN', {
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });
    } catch {
      return isoString;
    }
  };

  return (
    <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
      {/* Header & Controls */}
      <div className="p-4 border-b border-slate-100 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold text-slate-900">Live Gig Dispatch Monitor</h2>
          <p className="text-xs text-slate-500">
            Real-time synchronization with mobile customer bookings & worker acceptances
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {/* Search */}
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search customer, service, locality..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="text-xs pl-9 pr-3 py-2 rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-coop-primary w-56"
            />
          </div>

          {/* Filter Chips */}
          <div className="flex items-center bg-slate-100 p-1 rounded-lg">
            {['ALL', 'PENDING', 'ACTIVE', 'COMPLETED'].map((tab) => (
              <button
                key={tab}
                onClick={() => setFilterStatus(tab)}
                className={`text-xs px-3 py-1 rounded-md font-medium transition-colors ${
                  filterStatus === tab
                    ? 'bg-white text-slate-800 shadow-sm'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                {tab === 'ACTIVE' ? 'Active / In Progress' : tab.charAt(0) + tab.slice(1).toLowerCase()}
              </button>
            ))}
          </div>

          {/* Refresh Button */}
          <button
            onClick={onRefresh}
            disabled={isLoading}
            className="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600 hover:text-slate-900 transition-colors"
            title="Refresh Live Data"
          >
            <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin text-coop-primary' : ''}`} />
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs text-slate-600">
          <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-100 uppercase tracking-wider text-[11px]">
            <tr>
              <th className="py-3.5 px-4">Booking Ref / Time</th>
              <th className="py-3.5 px-4">Service & Payout</th>
              <th className="py-3.5 px-4">Customer Details</th>
              <th className="py-3.5 px-4">Service Location</th>
              <th className="py-3.5 px-4">Assigned Technician</th>
              <th className="py-3.5 px-4">Current Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {filteredBookings.length === 0 ? (
              <tr>
                <td colSpan={6} className="text-center py-10 text-slate-400">
                  {isLoading ? 'Fetching live database bookings...' : 'No bookings found matching current filters.'}
                </td>
              </tr>
            ) : (
              filteredBookings.map((b) => (
                <tr key={b.booking_id} className="hover:bg-slate-50/75 transition-colors">
                  <td className="py-3.5 px-4">
                    <div className="font-semibold text-slate-900 font-mono text-[11px]">
                      #{b.booking_id.slice(0, 8)}
                    </div>
                    <div className="text-[11px] text-slate-400 mt-0.5">{formatDate(b.scheduled_at || b.created_at)}</div>
                  </td>
                  <td className="py-3.5 px-4">
                    <div className="font-semibold text-slate-900">{b.services?.name || 'Home Service'}</div>
                    <div className="text-[11px] text-coop-primary font-bold mt-0.5">
                      {formatPrice(b.services?.base_price_amount)}
                    </div>
                  </td>
                  <td className="py-3.5 px-4">
                    <div className="font-semibold text-slate-800">{b.profiles?.full_name || 'Customer'}</div>
                    <div className="text-[11px] text-slate-400 mt-0.5">{b.profiles?.phone || '+91 98765 43210'}</div>
                  </td>
                  <td className="py-3.5 px-4 max-w-[200px] truncate">
                    <span className="text-slate-700">{b.address || 'Indiranagar, Bengaluru'}</span>
                  </td>
                  <td className="py-3.5 px-4">
                    {b.worker_id ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-slate-100 font-medium text-slate-800 text-[11px]">
                        Technician Assigned
                      </span>
                    ) : (
                      <span className="text-amber-600 font-medium text-[11px] italic">
                        Awaiting Worker Accept...
                      </span>
                    )}
                  </td>
                  <td className="py-3.5 px-4">{getStatusBadge(b.status)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
