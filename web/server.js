import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

// Load .env in non-production or when present
import fs from 'fs';
if (fs.existsSync('.env')) {
  // Dynamically import dotenv so it remains optional
  // eslint-disable-next-line no-unused-vars
  const dotenv = await import('dotenv');
  dotenv.config();
}

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Configuration via environment (with sensible defaults)
const PORT = process.env.PORT || 3000;
const LIVENESS_PATH = process.env.LIVENESS_PATH || '/health';
const READINESS_PATH = process.env.READINESS_PATH || '/ready';
const STATIC_DIR = process.env.STATIC_DIR || 'dist';
const READY_CHECK_URL = process.env.READY_CHECK_URL || '';
const READY_CHECK_TIMEOUT_MS = parseInt(process.env.READY_CHECK_TIMEOUT_MS || '2000', 10);

// Liveness endpoint
app.get(LIVENESS_PATH, (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Readiness endpoint
app.get(READINESS_PATH, async (req, res) => {
  // If an upstream check URL is configured, attempt a HEAD request to it
  if (READY_CHECK_URL) {
    try {
      const controller = new AbortController();
      const id = setTimeout(() => controller.abort(), READY_CHECK_TIMEOUT_MS);
      const resp = await fetch(READY_CHECK_URL, { method: 'HEAD', signal: controller.signal });
      clearTimeout(id);
      if (resp.ok) return res.status(200).json({ ready: true });
      return res.status(503).json({ ready: false, upstreamStatus: resp.status });
    } catch (err) {
      return res.status(503).json({ ready: false, error: err.message });
    }
  }

  // Default: ready
  return res.status(200).json({ ready: true });
});

// Serve the built static files from configured static directory
const staticPath = path.join(__dirname, STATIC_DIR);
if (fs.existsSync(staticPath)) {
  app.use(express.static(staticPath));

  // Fallback to index.html for client-side routing
  app.get('*', (req, res) => {
    res.sendFile(path.join(staticPath, 'index.html'));
  });
} else {
  app.get('*', (req, res) => {
    res.status(200).send('No static build found.');
  });
}

app.listen(PORT, () => {
  console.log(`Production server listening on port ${PORT}`);
  console.log(`Liveness: ${LIVENESS_PATH}, Readiness: ${READINESS_PATH}, Static dir: ${STATIC_DIR}`);
});
