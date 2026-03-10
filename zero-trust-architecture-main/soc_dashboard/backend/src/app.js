const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const metricsRouter = require('./api/metrics');
const eventsRouter = require('./api/events');
const alertsRouter = require('./api/alerts');
const providersRouter = require('./api/providers');
const usersRouter = require('./api/users');

const app = express();
app.use(express.json());
app.use('/metrics', metricsRouter);
app.use('/events', eventsRouter);
app.use('/alerts', alertsRouter);
app.use('/providers', providersRouter);
app.use('/users', usersRouter);

const server = http.createServer(app);
const io = new Server(server);

io.on('connection', (socket) => {
  // Example: send queue updates every second
  setInterval(() => {
    socket.emit('queue_update', { depth: Math.floor(Math.random() * 200) });
  }, 1000);
});

server.listen(8080, () => {
  console.log('SOC Dashboard backend running on port 8080');
});
