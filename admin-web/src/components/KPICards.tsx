import React from 'react';
import { PlatformKPIs } from '../types';
import { CalendarCheck, CheckCircle2, IndianRupee, Clock } from 'lucide-react';

interface KPICardsProps {
  kpis: PlatformKPIs;
  onFilterSelect?: (status: string) => void;
}

export const KPICards: React.FC<KPICardsProps> = ({ kpis, onFilterSelect }) => {
  const formattedRevenue = (kpis.totalEarningsPaise / 100).toLocaleString('en-IN', {
    maximumFractionDigits: 0,
  });

  const cards = [
    {
      title: 'Total Bookings',
      value: kpis.totalBookings,
      subtitle: 'All customer requests',
      filter: 'ALL',
      icon: CalendarCheck,
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
      borderColor: 'border-blue-100',
    },
    {
      title: 'Pending Dispatch',
      value: kpis.pendingBookings,
      subtitle: 'Click to filter pending',
      filter: 'PENDING',
      icon: Clock,
      color: 'text-amber-600',
      bgColor: 'bg-amber-50',
      borderColor: 'border-amber-100',
    },
    {
      title: 'Completed Gigs',
      value: kpis.completedBookings,
      subtitle: 'Click to filter completed',
      filter: 'COMPLETED',
      icon: CheckCircle2,
      color: 'text-emerald-600',
      bgColor: 'bg-emerald-50',
      borderColor: 'border-emerald-100',
    },
    {
      title: 'Worker Earnings',
      value: `₹${formattedRevenue}`,
      subtitle: 'Direct member payout pool',
      filter: 'COMPLETED',
      icon: IndianRupee,
      color: 'text-coop-primary',
      bgColor: 'bg-coop-50',
      borderColor: 'border-coop-100',
    },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      {cards.map((card, index) => {
        const Icon = card.icon;
        return (
          <div
            key={index}
            onClick={() => onFilterSelect && onFilterSelect(card.filter)}
            className={`p-5 rounded-xl bg-white border ${card.borderColor} shadow-sm hover:shadow-md transition-all cursor-pointer hover:border-coop-primary flex items-start justify-between group`}
          >
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider text-slate-500 group-hover:text-coop-primary transition-colors">
                {card.title}
              </p>
              <h3 className="text-2xl font-bold text-slate-800 mt-1">{card.value}</h3>
              <p className="text-xs text-slate-400 mt-1">{card.subtitle}</p>
            </div>
            <div className={`p-3 rounded-lg ${card.bgColor} ${card.color} group-hover:scale-105 transition-transform`}>
              <Icon className="w-5 h-5" />
            </div>
          </div>
        );
      })}
    </div>
  );
};
