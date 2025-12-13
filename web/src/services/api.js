import axios from 'axios';
import config from '../config';

// Create API instances for different services
export const api = axios.create({
  baseURL: config.apiUrl,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true,
});

export const streamingApi = axios.create({
  baseURL: config.streamingUrl,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true,
});

export const chatApi = axios.create({
  baseURL: config.chatUrl,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true,
});

export const coreApi = axios.create({
  baseURL: config.coreApiUrl,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true,
});

// Common request interceptor for all API instances
const requestInterceptor = (config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
};

// Common response interceptor for all API instances
const responseInterceptor = (response) => response;
const responseErrorInterceptor = (error) => {
  if (error.response?.status === 401) {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = '/login';
  }
  return Promise.reject(error);
};

// Apply interceptors to all API instances
[api, streamingApi, chatApi, coreApi].forEach(apiInstance => {
  apiInstance.interceptors.request.use(requestInterceptor, (error) => Promise.reject(error));
  apiInstance.interceptors.response.use(responseInterceptor, responseErrorInterceptor);
});
