import React, { useState, useEffect } from 'react';
import { WorkerItem } from '../types';
import { updateWorkerVerification } from '../services/api';
import { UserCheck, UserX, Star, ShieldCheck, Phone, CheckCircle, Clock } from 'lucide-react';

interface WorkerVerificationProps {
  workers: WorkerItem[];
  onUpdate: () => void;
}

export const WorkerVerification: React.FC<WorkerVerificationProps> = ({
  workers,
  onUpdate,
}) => {
  const [localWorkers, setLocalWorkers] = useState<WorkerItem[]>(workers);
  const [loadingId, setLoadingId] = useState<string | null>(null);

  useEffect(() => {
    setLocalWorkers(workers);
  }, [workers]);

  const handleVerify = async (workerId: string, status: 'VERIFIED' | 'REJECTED') => {
    setLoadingId(workerId);

    // Optimistic UI Update: immediately change status on screen
    setLocalWorkers((prev) =>
      prev.map((w) => (w.worker_id === workerId ? { ...w, verification_status: status } : w))
    );

    const success = await updateWorkerVerification(workerId, status);
    setLoadingId(null);
    if (success) {
      onUpdate();
    }
  };

  const verifiedCount = localWorkers.filter((w) => w.verification_status === 'VERIFIED').length;

  return (
    <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden mt-6">
      <div className="p-4 border-b border-slate-100 flex items-center justify-between">
        <div>
          <h2 className="text-lg font-bold text-slate-900">Cooperative Worker Verification Registry</h2>
          <p className="text-xs text-slate-500">
            Verify newly registered cooperative tradespersons, skill credentials & welfare enrollment
          </p>
        </div>
        <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-coop-50 text-coop-primary border border-coop-200">
          {verifiedCount} Verified Members
        </span>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs text-slate-600">
          <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-100 uppercase tracking-wider text-[11px]">
            <tr>
              <th className="py-3.5 px-4">Technician</th>
              <th className="py-3.5 px-4">Skills / Certified Trade</th>
              <th className="py-3.5 px-4">Contact Phone</th>
              <th className="py-3.5 px-4">Rating</th>
              <th className="py-3.5 px-4">Verification Status</th>
              <th className="py-3.5 px-4 text-right">Federation Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {localWorkers.length === 0 ? (
              <tr>
                <td colSpan={6} className="text-center py-10 text-slate-400">
                  No registered cooperative workers found.
                </td>
              </tr>
            ) : (
              localWorkers.map((worker) => (
                <tr key={worker.worker_id} className="hover:bg-slate-50/75 transition-colors">
                  <td className="py-3.5 px-4">
                    <div className="font-semibold text-slate-900 flex items-center gap-1.5">
                      {worker.full_name}
                      {worker.verification_status === 'VERIFIED' && (
                        <ShieldCheck className="w-3.5 h-3.5 text-coop-primary inline" />
                      )}
                    </div>
                    <div className="text-[11px] text-slate-400 font-mono">ID: {worker.worker_id.slice(0, 8)}</div>
                  </td>
                  <td className="py-3.5 px-4">
                    <div className="flex flex-wrap gap-1">
                      {worker.skills.map((skill, idx) => (
                        <span
                          key={idx}
                          className="px-2 py-0.5 rounded bg-slate-100 text-slate-700 font-medium text-[10px]"
                        >
                          {skill}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="py-3.5 px-4">
                    <div className="flex items-center gap-1 text-slate-700">
                      <Phone className="w-3 h-3 text-slate-400" />
                      {worker.phone || '+91 98765 11223'}
                    </div>
                  </td>
                  <td className="py-3.5 px-4">
                    <div className="flex items-center gap-1 font-semibold text-slate-800">
                      <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
                      {worker.rating_avg.toFixed(1)}
                      <span className="text-[10px] text-slate-400 font-normal">({worker.rating_count})</span>
                    </div>
                  </td>
                  <td className="py-3.5 px-4">
                    {worker.verification_status === 'VERIFIED' ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full font-semibold text-[11px] bg-emerald-50 text-emerald-700 border border-emerald-200">
                        <CheckCircle className="w-3 h-3" /> Verified
                      </span>
                    ) : worker.verification_status === 'PENDING' ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full font-semibold text-[11px] bg-amber-50 text-amber-700 border border-amber-200">
                        <Clock className="w-3 h-3" /> Pending Review
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full font-semibold text-[11px] bg-rose-50 text-rose-700 border border-rose-200">
                        Rejected
                      </span>
                    )}
                  </td>
                  <td className="py-3.5 px-4 text-right">
                    {worker.verification_status !== 'VERIFIED' ? (
                      <div className="inline-flex items-center gap-1.5 justify-end">
                        <button
                          onClick={() => handleVerify(worker.worker_id, 'VERIFIED')}
                          disabled={loadingId === worker.worker_id}
                          className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-coop-primary text-white font-semibold text-xs hover:bg-coop-dark transition-colors shadow-sm disabled:opacity-50 cursor-pointer"
                        >
                          <UserCheck className="w-3.5 h-3.5" /> Approve
                        </button>
                        <button
                          onClick={() => handleVerify(worker.worker_id, 'REJECTED')}
                          disabled={loadingId === worker.worker_id}
                          className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-slate-100 text-slate-600 font-semibold text-xs hover:bg-rose-50 hover:text-rose-600 transition-colors disabled:opacity-50 cursor-pointer"
                        >
                          <UserX className="w-3.5 h-3.5" /> Reject
                        </button>
                      </div>
                    ) : (
                      <span className="text-[11px] text-slate-400 font-medium">On-Duty Active</span>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
