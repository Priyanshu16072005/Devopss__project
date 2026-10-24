// Empty VITE_API_URL = same origin (Vite proxy in dev, Nginx proxy in Docker).
// Set it only when the API lives on another domain (e.g. Vercel + Render).
const API_BASE = `${import.meta.env.VITE_API_URL || ''}/api`;

function getToken() {
  return localStorage.getItem('token');
}

async function request(path, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...options.headers };
  const token = getToken();

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers
  });

  const data = await res.json().catch(() => ({}));

  if (!res.ok) {
    throw new Error(data.message || 'Request failed');
  }

  return data;
}

export const api = {
  register: (body) =>
    request('/register', {
      method: 'POST',
      body: JSON.stringify(body)
    }),

  login: (body) =>
    request('/login', {
      method: 'POST',
      body: JSON.stringify(body)
    }),

  me: () => request('/me'),

  getStats: () => request('/stats'),

  donate: (body) =>
    request('/donate', {
      method: 'POST',
      body: JSON.stringify(body)
    }),

  getDonations: (params = '') => request(`/donations${params}`),

  updateDonation: (id, body) =>
    request(`/donation/${id}`, {
      method: 'PUT',
      body: JSON.stringify(body)
    }),

  deleteDonation: (id) =>
    request(`/donation/${id}`, {
      method: 'DELETE'
    }),

  getDeliveries: () => request('/deliveries'),

  assignVolunteer: (body) =>
    request('/assign-volunteer', {
      method: 'POST',
      body: JSON.stringify(body)
    }),

  pickTask: (body) =>
    request('/pick-task', {
      method: 'POST',
      body: JSON.stringify(body)
    }),

  updateDeliveryStatus: (id, body) =>
    request(`/delivery-status/${id}`, {
      method: 'PUT',
      body: JSON.stringify(body)
    }),

  getUsers: () => request('/admin/users'),

  getAnalytics: () => request('/admin/analytics'),

  deleteUser: (id) =>
    request(`/admin/users/${id}`, {
      method: 'DELETE'
    }),
};