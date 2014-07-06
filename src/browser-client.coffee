# vim: ft=coffee
clients = require './all-clients'

if window?
  window.EpiClient = clients.EpiClient
  window.EpiBufferingClient = clients.EpiBufferingClient
  window.EpiSimpleClient = clients.EpiSimpleClient
