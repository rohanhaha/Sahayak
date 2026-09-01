import React, { useState } from 'react';
import { Booking, BookingStatus } from '../types';
import { updateBookingStatus } from '../services/api';
import {
  Search,
  Clock,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
  Eye,
  X,
  MapPin,
  User,
  Phone,
  Calendar,
  FileText,
  DollarSign,
  ShieldCheck,
} from 'lucide-react';

interface BookingsTableProps {
  bookings: Booking[];
  isLoading: boolean;
  onRefresh: () => void;
  filterStatus?: string;
  onFilterChange?: (status: string) => void;
}

export const BookingsTable: React.FC<BookingsTableProps> = ({
  bookings,
  isLoading,
  onRefresh,
  filterStatus: externalFilter,
  onFilterChange,
}) => {
  const [internalFilter, setInternalFilter] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedBooking, setSelectedBooking] = useState<Booking | null>(null);
  const [isUpdatingStatus, setIsUpdatingStatus] = useState<boolean>(false);

  const activeFilter = externalFilter || internalFilter;
  const handleFilterSelect = (status: string) => {
    if (onFilterChange) {
      onFilterChange(status);
    } else {
      setInternalFilter(status);
    }
  };

  const filteredBookings = bookings.filter((b) => {
    const matchesStatus =
      activeFilter === 'ALL' ||
      (activeFilter === 'ACTIVE' && (b.status === 'ACCEPTED' || b.status === 'IN_PROGRESS')) ||
      b.status === activeFilter;

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

  const handleStatusChange = async (newStatus: BookingStatus) => {
    if (!selectedBooking) return;
    setIsUpdatingStatus(true);
    const success = await updateBookingStatus(selectedBooking.booking_id, newStatus);
    setIsUpdatingStatus(false);
    if (success) {
      setSelectedBooking({ ...selectedBooking, status: newStatus });
      onRefresh();
    }
  };

  return (
    <>
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        {/* Header & Controls */}
        <div className="p-4 border-b border-slate-100 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <div>
            <h2 className="text-lg font-bold text-slate-900">Live Gig Dispatch Monitor</h2>
            <p className="text-xs text-slate-500">
              Click any booking row to view customer dispatch details & manage status
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {/* Search */}
            <div className="relative">
              <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                placeholder="Search customer, service..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="text-xs pl-9 pr-3 py-2 rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-coop-primary w-52"
              />
            </div>

            {/* Filter Chips */}
            <div className="flex items-center bg-slate-100 p-1 rounded-lg">
              {['ALL', 'PENDING', 'ACTIVE', 'COMPLETED'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => handleFilterSelect(tab)}
                  className={`text-xs px-3 py-1 rounded-md font-medium transition-colors ${
                    activeFilter === tab
                      ? 'bg-white text-slate-800 shadow-sm font-bold'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  {tab === 'ACTIVE' ? 'Active' : tab.charAt(0) + tab.slice(1).toLowerCase()}
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
                <th className="py-3.5 px-4 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredBookings.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-10 text-slate-400">
                    {isLoading ? 'Fetching live database bookings...' : 'No bookings found matching current filters.'}
                  </td>
                </tr>
              ) : (
                filteredBookings.map((b) => (
                  <tr
                    key={b.booking_id}
                    onClick={() => setSelectedBooking(b)}
                    className="hover:bg-slate-50/90 transition-colors cursor-pointer group"
                  >
                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-slate-900 font-mono text-[11px] group-hover:text-coop-primary transition-colors">
                        #{b.booking_id.slice(0, 8)}
                      </div>
                      <div className="text-[11px] text-slate-400 mt-0.5">
                        {formatDate(b.scheduled_at || b.created_at)}
                      </div>
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
                    <td className="py-3.5 px-4 max-w-[180px] truncate">
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
                    <td className="py-3.5 px-4 text-right">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedBooking(b);
                        }}
                        className="p-1.5 rounded-lg text-slate-400 hover:text-coop-primary hover:bg-coop-50 transition-colors"
                        title="View Details"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Interactive Booking Details Modal */}
      {selectedBooking && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-xs animate-in fade-in duration-150">
          <div className="bg-white rounded-2xl shadow-xl border border-slate-200 max-w-lg w-full overflow-hidden">
            {/* Modal Header */}
            <div className="px-6 py-4 bg-slate-50 border-b border-slate-100 flex items-center justify-between">
              <div>
                <span className="text-xs font-mono text-slate-400">BOOKING INSPECTION</span>
                <h3 className="text-base font-bold text-slate-900">
                  #{selectedBooking.booking_id.slice(0, 8)} • {selectedBooking.services?.name || 'Service'}
                </h3>
              </div>
              <button
                onClick={() => setSelectedBooking(null)}
                className="p-1.5 rounded-lg hover:bg-slate-200 text-slate-400 hover:text-slate-700 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 space-y-4">
              {/* Status & Price Row */}
              <div className="flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-100">
                <div>
                  <div className="text-[11px] text-slate-400 font-medium">CURRENT STATUS</div>
                  <div className="mt-1">{getStatusBadge(selectedBooking.status)}</div>
                </div>
                <div className="text-right">
                  <div className="text-[11px] text-slate-400 font-medium">TOTAL PAYOUT</div>
                  <div className="text-lg font-extrabold text-coop-primary mt-0.5">
                    {formatPrice(selectedBooking.services?.base_price_amount)}
                  </div>
                </div>
              </div>

              {/* Customer Info */}
              <div className="space-y-2">
                <div className="text-xs font-bold uppercase text-slate-500 tracking-wider">
                  Customer Information
                </div>
                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div className="flex items-center gap-2 p-2.5 rounded-lg border border-slate-100">
                    <User className="w-4 h-4 text-slate-400" />
                    <span className="font-semibold text-slate-800">
                      {selectedBooking.profiles?.full_name || 'Customer'}
                    </span>
                  </div>
                  <div className="flex items-center gap-2 p-2.5 rounded-lg border border-slate-100">
                    <Phone className="w-4 h-4 text-slate-400" />
                    <span className="text-slate-700">{selectedBooking.profiles?.phone || '+91 98765 43210'}</span>
                  </div>
                </div>
              </div>

              {/* Location & Time */}
              <div className="space-y-2">
                <div className="text-xs font-bold uppercase text-slate-500 tracking-wider">
                  Dispatch Details
                </div>
                <div className="flex items-start gap-2 p-2.5 rounded-lg border border-slate-100 text-xs">
                  <MapPin className="w-4 h-4 text-slate-400 shrink-0 mt-0.5" />
                  <div>
                    <div className="font-medium text-slate-800">{selectedBooking.address || 'Indiranagar, Bengaluru'}</div>
                    <div className="text-[11px] text-slate-400">Lat: 12.9716, Lng: 77.5946</div>
                  </div>
                </div>
                {selectedBooking.notes && (
                  <div className="flex items-start gap-2 p-2.5 rounded-lg bg-amber-50/50 border border-amber-100 text-xs">
                    <FileText className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                    <span className="text-slate-700">Notes: {selectedBooking.notes}</span>
                  </div>
                )}
              </div>

              {/* Admin Action Bar */}
              <div className="pt-2 border-t border-slate-100">
                <div className="text-xs font-bold text-slate-700 mb-2">
                  Override Status (Cooperative Admin Action):
                </div>
                <div className="grid grid-cols-3 gap-2">
                  <button
                    onClick={() => handleStatusChange('ACCEPTED')}
                    disabled={isUpdatingStatus}
                    className="py-2 px-3 rounded-lg text-xs font-bold bg-blue-50 text-blue-700 border border-blue-200 hover:bg-blue-100 transition-colors disabled:opacity-50"
                  >
                    Accept
                  </button>
                  <button
                    onClick={() => handleStatusChange('IN_PROGRESS')}
                    disabled={isUpdatingStatus}
                    className="py-2 px-3 rounded-lg text-xs font-bold bg-indigo-50 text-indigo-700 border border-indigo-200 hover:bg-indigo-100 transition-colors disabled:opacity-50"
                  >
                    In Progress
                  </button>
                  <button
                    onClick={() => handleStatusChange('COMPLETED')}
                    disabled={isUpdatingStatus}
                    className="py-2 px-3 rounded-lg text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100 transition-colors disabled:opacity-50"
                  >
                    Complete
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
};
