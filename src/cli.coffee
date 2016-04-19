#! /usr/bin/env coffee
{area, building, search} = require "../lib/scraper"

# area().then (res) ->
#   console.log res
# scraper "中央区", "舞鶴公園", "野球場"
building("中央区").then (res) ->
  console.log res
# scraper "中央区", "舞鶴公園", "野球場"
.catch (reason) ->
  console.error reason
