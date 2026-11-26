import cors from 'cors';
import express from 'express';
import helmet from 'helmet';

import { errorHandler } from './middleware/error-handler.js';
import { notFound } from './middleware/not-found.js';
import { healthRouter } from './routes/health.routes.js';

export function createApp({ corsOrigins = [] } = {}) {
  const app = express();
  app.use(helmet());
  if (corsOrigins.length > 0) {
    app.use(cors({ origin: corsOrigins }));
  }
  app.use(express.json({ limit: '100kb' }));
  app.use(healthRouter);
  app.use(notFound);
  app.use(errorHandler);
  return app;
}
