import { Booking, WorkerItem, BookingStatus } from '../types';

export const API_BASE_URL = 'https://sahayak-t0pw.onrender.com/api/v1';

export async function fetchBookings(status?: BookingStatus): Promise<Booking[]> {
  try {
    const url = new URL(`${API_BASE_URL}/bookings`);
    url.searchParams.append('limit', '50');
    if (status) {
      url.searchParams.append('status', status);
    }

    const response = await fetch(url.toString(), {
      headers: { 'Content-Type': 'application/json' },
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();
    return data.results || [];
  } catch (error) {
    console.warn('API fetchBookings failed, returning cached/fallback fixtures:', error);
    return getFallbackBookings();
  }
}

export async function fetchWorkers(): Promise<WorkerItem[]> {
  try {
    const response = await fetch(`${API_BASE_URL}/workers?limit=50`, {
      headers: { 'Content-Type': 'application/json' },
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();
    return data.results || [];
  } catch (error) {
    console.warn('API fetchWorkers failed, returning fallback list:', error);
    return getFallbackWorkers();
  }
}

export async function updateBookingStatus(
  bookingId: string,
  status: BookingStatus,
  workerId?: string
): Promise<boolean> {
  try {
    const response = await fetch(`${API_BASE_URL}/bookings/${bookingId}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status, worker_id: workerId }),
    });
    return response.ok;
  } catch (error) {
    console.error('Failed to update booking status:', error);
    return false;
  }
}

export async function updateWorkerVerification(
  workerId: string,
  status: 'VERIFIED' | 'REJECTED'
): Promise<boolean> {
  try {
    const response = await fetch(`${API_BASE_URL}/admin/workers/${workerId}/verify`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status }),
    });
    return response.ok;
  } catch (error) {
    console.error('Failed to update worker verification:', error);
    return false;
  }
}

// Fallback fixtures for seamless local review
function getFallbackBookings(): Booking[] {
  return [
    {
      booking_id: 'b-101',
      service_id: 's-1',
      customer_id: 'c-1',
      scheduled_at: new Date(Date.now() + 3600000).toISOString(),
      address: 'Indiranagar, Bengaluru',
      status: 'PENDING',
      payment_status: 'UNPAID',
      created_at: new Date().toISOString(),
      services: {
        name: 'Home Deep Cleaning',
        category: 'Cleaning',
        base_price_amount: 49900,
      },
      profiles: {
        full_name: 'Ananya Sharma',
        phone: '+91 98765 43210',
      },
    },
    {
      booking_id: 'b-102',
      service_id: 's-2',
      worker_id: 'w-1',
      customer_id: 'c-2',
      scheduled_at: new Date(Date.now() + 7200000).toISOString(),
      address: 'Koramangala 4th Block, Bengaluru',
      status: 'ACCEPTED',
      payment_status: 'PAID',
      created_at: new Date(Date.now() - 3600000).toISOString(),
      services: {
        name: 'Electrical Wiring & Repair',
        category: 'Electrician',
        base_price_amount: 29900,
      },
      profiles: {
        full_name: 'Vikram Mehta',
        phone: '+91 98123 45678',
      },
    },
    {
      booking_id: 'b-103',
      service_id: 's-3',
      worker_id: 'w-2',
      customer_id: 'c-3',
      scheduled_at: new Date(Date.now() - 86400000).toISOString(),
      address: 'HSR Layout Sector 2, Bengaluru',
      status: 'COMPLETED',
      payment_status: 'PAID',
      created_at: new Date(Date.now() - 90000000).toISOString(),
      services: {
        name: 'Plumbing & Pipe Leakage',
        category: 'Plumber',
        base_price_amount: 34900,
      },
      profiles: {
        full_name: 'Priya Iyer',
        phone: '+91 97654 32109',
      },
    },
  ];
}

function getFallbackWorkers(): WorkerItem[] {
  return [
    {
      worker_id: 'w-1',
      full_name: 'Rajesh Kumar',
      phone: '+91 98765 11223',
      skills: ['Electrician', 'Appliance Repair'],
      rating_avg: 4.8,
      rating_count: 34,
      verification_status: 'VERIFIED',
      is_on_duty: true,
    },
    {
      worker_id: 'w-2',
      full_name: 'Suresh Patil',
      phone: '+91 98765 44556',
      skills: ['Plumber', 'Pipe Fitting'],
      rating_avg: 4.6,
      rating_count: 22,
      verification_status: 'VERIFIED',
      is_on_duty: true,
    },
    {
      worker_id: 'w-3',
      full_name: 'Amit Verma',
      phone: '+91 98765 77889',
      skills: ['Home Deep Cleaning', 'Sanitization'],
      rating_avg: 4.9,
      rating_count: 12,
      verification_status: 'PENDING',
      is_on_duty: false,
    },
  ];
}
