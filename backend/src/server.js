const express = require('express');
require('dotenv').config({ debug: true });
const app = express();
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', 'http://localhost:3000'); // React-адрес
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  next();
});
const port = process.env.PORT || 3001;
app.get('/', (req, res) => {
  res.json({ status: "Server is running!" });
});
// 5. Запускаем сервер
app.listen(port, () => {
  console.log(`http://localhost:${port}`);
});