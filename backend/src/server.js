const express = require('express');
require('dotenv').config();
const app = express();

const port = process.env.PORT || 3001;
app.get('/', (req, res) => {
  res.json({ status: "Server is running!" });
});
// 5. Запускаем сервер
app.listen(port, () => {
  console.log(`http://localhost:${port}`);
});