# vim: ft=coffee
clients = require './epi-client'

if window?
  window.EpiClient = clients.EpiClient
  window.EpiBufferingClient = clients.EpiBufferingClient
