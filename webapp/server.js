const express = require("express");
const os = require("os");

const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.json({
    status: "ok",
    server: os.hostname(),
    hostname: os.hostname(),
    port: PORT,
    timestamp: new Date().toISOString()
  });
});

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    server: os.hostname(),
    port: PORT
  });
});

app.get("/api/info", (req, res) => {
  res.json({
    server: os.hostname(),
    hostname: os.hostname(),
    port: PORT,
    platform: os.platform(),
    uptime: os.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(
    `Servidor ${os.hostname()} escuchando en puerto ${PORT}`
  );
});