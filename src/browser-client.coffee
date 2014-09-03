# vim: ft=coffee
clients = require '../index'

if window?
  window.EpiClient = clients.EpiClient
  window.EpiBufferingClient = clients.EpiBufferingClient