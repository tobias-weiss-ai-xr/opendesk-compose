'use strict';

// =============================================================================
// CryptPad Configuration — openDesk Compose
// Behind Traefik reverse proxy. All traffic goes through HTTPS.
// Domains are set from .env.production via environment substitution.
// =============================================================================

module.exports = {
  // --- Domains ---
  // Behind Traefik: unsafe = HTTP (internal), safe = HTTPS (external proxy)
  // Both point to the same CryptPad instance. Traefik handles TLS termination.
  httpUnsafeOrigin: process.env.CPAD_HTTP_UNSAFE || 'http://cryptpad:3000',
  httpSafeOrigin: process.env.CPAD_HTTP_SAFE || 'https://pad.' + (process.env.DOMAIN || 'localhost'),

  // --- Storage ---
  filePath: '/cryptpad/data',
  archivePath: '/cryptpad/data/archive',
  blobPath: '/cryptpad/blob',
  blobStagingPath: '/cryptpad/data/blobstage',
  blockPath: '/cryptpad/block',
  dataPath: '/cryptpad/data',

  // --- Database ---
  dbPath: '/cryptpad/data',

  // --- Admin ---
  // Set admin keys after first login: inspect the logs for the admin key
  adminEmail: process.env.CPAD_ADMIN_EMAIL || 'admin@' + (process.env.DOMAIN || 'localhost'),
  adminKeys: [],

  // --- Limits ---
  defaultStorageLimit: 50 * 1024 * 1024 * 1024, // 50GB
  maxUploadSize: 20 * 1024 * 1024 * 1024,          // 20GB

  // --- Features ---
  enableEmbedding: true,
  enablePadsForGuests: true,
  enableTemplates: true,
  enableRegistration: false,  // OpenDesk: registration via Keycloak only

  // --- Cryptography ---
  suppressDHKeys: true,
  disableWebsocketCompression: false,

  // --- Pad types ---
  availablePadTypes: [
    'pad',
    'code',
    'slide',
    'poll',
    'kanban',
    'diagram',
    'sheet',
    'doc',
    'presentation',
  ],

  // --- WebSocket ---
  websocket: {
    pingInterval: 5000,
  },

  // --- Content Security ---
  httpHeaders: {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "sameorigin",
  },

  // --- Logging ---
  log: {
    level: 'info',
  },

  // --- Session ---
  sessionSecret: process.env.CPAD_SESSION_SECRET || 'changeme-in-production',
};
