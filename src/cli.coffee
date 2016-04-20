#! /usr/bin/env coffee
{area, building, institution, search} = require "../lib/scraper"

# area().then (res) ->
#   console.log res
# # scraper "中央区", "舞鶴公園", "野球場"
# building("中央区").then (res) ->
#   console.log res
# # scraper "中央区", "舞鶴公園", "野球場"
# institution("中央区", "舞鶴公園").then (res) ->
#   console.log res
search "中央区", "舞鶴公園", "野球場", 25
.then (res) ->
  console.log res
.catch (reason) ->
  console.error reason
