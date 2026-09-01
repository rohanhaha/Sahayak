import React from 'react';
import { PlatformKPIs } from '../types';
import { CalendarCheck, Users, CheckCircle2, IndianRupee, Clock } from 'lucide-react';

interface KPICardsProps {
  kpis: PlatformKPIs;
}

export const KPICards: React.FC<KPICardsProps> = ({ kpis }) => {
  const formattedRevenue = (kpis.totalEarningsPaise / 100).toLocaleString('en-IN', {
    maximumFractionDigits: 0,
  });

  const cards = [
    {
      title: 'Total Bookings',
      value: kpis.totalBookings,
      subtitle: 'All customer requests',
      icon: CalendarCheck,
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
      borderColor: 'border-blue-100',
    },
    {
      title: 'Pending Dispatch',
      value: kpis.pendingBookings,
      subtitle: 'Awaiting worker acceptance',
      icon: Clock,
      color: 'text-amber-600',
      bgColor: 'bg-amber-50',
      borderColor: 'border-amber-100',
    },
    {
      title: 'Completed Gigs',
      value: kpis.completedBookings,
      subtitle: '100% verified resolution',
      icon: CheckCircle2,
      color: 'text-emerald-600',
      bgColor: 'bg-emerald-50',
      borderColor: 'border-emerald-100',
    },
    {
      title: 'Worker Earnings',
      value: `₹${formattedRevenue}`,
      subtitle: 'Direct member payout pool',
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
            className={`p-5 rounded-xl bg-white border ${card.borderColor} shadow-sm hover:shadow-md transition-shadow flex items-start justify-between`}
          >
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">
                {card.title}
              </p>
              <h3 className="text-2xl font-bold text-slate-800 mt-1">{card.value}</h3>
              <p className="text-xs text-slate-400 mt-1">{card.subtitle}</p>
            </div>
            <div className={`p-3 rounded-lg ${card.bgColor} ${card.color}`}>
              <Icon className="w-5 h-5" />
            </div>
          </div>
        );
      })}
    </div>
  );
};
