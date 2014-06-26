var clients;

clients = require('./epi-client');

if (typeof window !== "undefined" && window !== null) {
  window.EpiClient = clients.EpiClient;
  window.EpiBufferingClient = clients.EpiBufferingClient;
}
