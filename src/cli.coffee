#! /usr/bin/env coffee
#
# cli.coffee
#
# Copyright (c) 2016 Junpei Kawamoto
#
# This software is released under the MIT License.
#
# http://opensource.org/licenses/mit-license.php
#
yargs = require "yargs"
{area, building, institution, status} = require "../lib/scraper"

argv = yargs
  .usage "Usage: $0 <command> [options]"
  .command "area", "List up areas.", {}, (args) ->
    area().then (res) ->
      res.forEach (v)->
        console.log v
  .command "building", "List up buildings in an area.",
    (yargs) ->
      yargs.option "area",
        rewuired: true
        describe: "Name of area."
    ,
    (args) ->
      building(args.area).then (res) ->
        res.forEach (v)->
          console.log v
  .command "institution", "List up institutions in a building",
    (yargs) ->
      yargs.option "area",
          required: true
          describe: "Name of area."
        .option "building",
          required: true
          describe: "Name of building."
    ,
    (args) ->
      institution(args.area, args.building).then (res) ->
        res.forEach (v)->
          console.log v
  .command "state", "Search reservation status.",
    (yargs) ->
      today = new Date()
      yargs.option "area",
          required: true
          describe: "Name of area."
        .option "building",
          required: true
          describe: "Name of building."
        .option "institution",
          required: true
          describe: "Name of institution."
        .option "year",
          default: today.getFullYear()
          describe: "Year."
        .option "month",
          default: today.getMonth() + 1
          describe: "Month."
        .option "day",
          default: today.getDay() + 1
          describe: "Day."
    ,
    (args) ->
      status args.area, args.building,
        args.institution, args.year, args.month, args.day
      .then (res) ->
        console.log JSON.stringify res, null, "  "
  .help()
  .argv


if argv._.length is 0
  yargs.showHelp()
