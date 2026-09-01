export type BookingStatus = 'PENDING' | 'ACCEPTED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';

export interface ServiceDetail {
  name: string;
  category: string;
  base_price_amount: number; // in paise (e.g. 49900 = ₹499)
  image_url?: string;
}

export interface CustomerProfile {
  full_name: string;
  phone?: string;
}

export interface Booking {
  booking_id: string;
  service_id: string;
  worker_id?: string | null;
  customer_id: string;
  scheduled_at: string;
  address: string;
  lat?: number | null;
  lng?: number | null;
  notes?: string;
  status: BookingStatus;
  payment_status: string;
  created_at: string;
  services?: ServiceDetail;
  profiles?: CustomerProfile;
}

export interface WorkerCertificate {
  name: string;
  file_url: string;
}

export interface WorkerItem {
  worker_id: string;
  full_name: string;
  phone?: string;
  skills: string[];
  certificates?: WorkerCertificate[];
  rating_avg: number;
  rating_count: number;
  verification_status: 'PENDING' | 'VERIFIED' | 'REJECTED';
  is_on_duty?: boolean;
}

export interface PlatformKPIs {
  totalBookings: number;
  pendingBookings: number;
  completedBookings: number;
  activeWorkers: number;
  totalEarningsPaise: number;
}
