#! /usr/bin/env coffee
{wards, search} = require "../lib/scraper"

wards().then (res) ->
  console.log res
# scraper "中央区", "舞鶴公園", "野球場"
