const express = require('express');
const app = express();

// Детальная настройка CORS
app.use((req, res, next) => {
  const allowedOrigins = [
    'https://psychic-engine-4jq5wp695vvwc7v99-3000.app.github.dev',
    'http://localhost:3000',
    'http://127.0.0.1:3000'
  ];
  
  const origin = req.headers.origin;
  if (allowedOrigins.includes(origin)) {
    res.header('Access-Control-Allow-Origin', origin);
  }
  
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Credentials', 'true');
  
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  next();
});

const port = 3001;

app.get('/api/status', (req, res) => {
  res.json({ 
    status: "Server is running!",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`✅ Сервер запущен: https://psychic-engine-4jq5wp695vvwc7v99-${port}.app.github.dev`);
});