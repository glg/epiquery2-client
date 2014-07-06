var clients;

clients = require('./all-clients');

if (typeof window !== "undefined" && window !== null) {
  window.EpiClient = clients.EpiClient;
  window.EpiBufferingClient = clients.EpiBufferingClient;
  window.EpiSimpleClient = clients.EpiSimpleClient;
}
