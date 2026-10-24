require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');//responsible for communication between frontend and backend
const connectDB = require('./config/db');

const authRoutes = require('./routes/authRoutes');
const donationRoutes = require('./routes/donationRoutes');
const deliveryRoutes = require('./routes/deliveryRoutes');
const adminRoutes = require('./routes/adminRoutes');
const { getPublicStats } = require('./controllers/statsController');

const app = express();
const PORT = process.env.PORT || 5000;

// Allow all origins by default; set CORS_ORIGIN=https://a.com,https://b.com to restrict.
const allowedOrigins = process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : '*';
app.use(cors({ origin: allowedOrigins }));
app.use(express.json());
//registerd routes to tell midleware that when this path come run middleware
app.get('/api/health', (_, res) => res.json({ status: 'ok', project: 'Food For All' }));
app.get('/api/stats', getPublicStats);

app.use('/api', authRoutes);
app.use('/api', donationRoutes);
app.use('/api', deliveryRoutes);
app.use('/api/admin', adminRoutes);

app.use((err, _req, res, _next) => {//global error catch
  console.error(err);
  res.status(500).json({ message: 'Internal server error' });
});

connectDB() //after calling this it immediately run await in db .js
  .then(() => { //.then methos wait for a while to connect mongodb completely
    const server = app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

    // Graceful shutdown: `docker stop` sends SIGTERM, so finish open requests
    // and close the MongoDB connection before the container exits.
    const shutdown = (signal) => {
      console.log(`${signal} received, shutting down`);
      server.close(async () => {
        await mongoose.connection.close();
        process.exit(0);
      });
    };
    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);
  })
  .catch((err) => {
    console.error('DB connection failed:', err.message);
    process.exit(1);
  });
