#
# scraper.coffee
#
# Copyright (c) 2016 Junpei Kawamoto
#
# This software is released under the MIT License.
#
# http://opensource.org/licenses/mit-license.php
#
phantom = require "phantom"
cheerio = require "cheerio"

# Root URL.
ROOT_URL = "https://www.comnet-fukuoka.jp/web/"

ATTESTATION_URL =
  "https://www.comnet-fukuoka.jp/web/rsvWTransUserAttestationAction.do"
VACANT_URL =
  "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchVacantAction.do"
AREA_URL =
  "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchAreaAction.do"
BUILDING_URL =
  "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchBuildAction.do"
INSTITUTION_URL =
  "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchInstAction.do"
DAY_WEEK_URL =
  "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchDayWeekAction.do"
RESULT_URL =
  "https://www.comnet-fukuoka.jp/web/rsvWInstSrchVacantAction.do"

# Ignored item name which measn "all".
IGNORED_KEYWORD = "すべて"

SRC_CLOSED = "image/lw_closes.gif"
SRC_AVAILABLE = "image/lw_emptybs.gif"
SRC_OCCUPIED = "image/lw_finishs.gif"
SRC_MAINTENANCE = "image/lw_keeps.gif"
SRC_OUT_OF_DATE = "image/lw_kikangais.gif"

STATUS =
  CLOSED: "closed"
  AVAILABLE: "available"
  OCCUPIED: "occupied"
  MAINTENANCE: "maintenance"
  OUT_OF_DATE: "out of date"

WAITING_TIME = 1500

# Execute a given tasks via PhantomJS.
#
# @param generator [Function] takes a page object and generates tasks.
# @return [Promise] which will pass the result.
run = (generator) ->

  new Promise (resolve, reject) ->

    phantom.create().then (instance) ->

      instance.createPage().then (page) ->

        # Observing URL until it becomes a given one.
        #
        # @param url [String] url string.
        # @return [Promise] invoked when the URL will be match to the given
        #     url.
        wait_moved_to = (url) ->
          new Promise (resolve, reject) ->
            do checker = ->
              page.property("url").then (res) ->
                res = res.split(";")[0]
                if res is url
                  resolve res
                else
                  setTimeout checker, WAITING_TIME

              .catch (reason) ->
                reject reason

        page.open(ROOT_URL)
          .then ->
            tasks = generator page
            new Promise (resolve, reject) ->
              do runner = ->
                t = tasks.shift()
                # console.log "move to", t.url
                wait_moved_to(t.url).then(t.action).then (res) ->
                  if tasks.length isnt 0
                    runner()
                  else
                    resolve res
                .catch (reason) ->
                  # console.log reason
                  reject reason

          .then (res) ->
            page.close()
            instance.exit()
            resolve res

          .catch (reason) ->
            console.error reason
            # Clean up.
            page.close()
            instance.exit()
            reject reason

      .catch (reason) ->
        reject reason

    .catch (reason) ->
      reject reason



# Generate common tasks.
#
# Such tasks are for skipping default pages.
#
# @param page [Page] Page object.
# @return [Array] array of tasks which contain url and action.
generate_common_tasks = (page) -> [
  url: ATTESTATION_URL
  action: ->
    page.evaluate ->
      action = if window._dom is 3
        document.layers['disp'].document.formWTransInstSrchVacantAction
      else
        document.formWTransInstSrchVacantAction
      window.doAction action, gRsvWTransInstSrchVacantAction
,
  url: VACANT_URL
  action: ->
    page.evaluate ->
      action = if window._dom is 3
        document.layers['disp'].document.formWTransInstSrchAreaAction
      else
        document.formWTransInstSrchAreaAction
      window.doAction action, gRsvWTransInstSrchAreaAction
]


# Create a task which searches a target link and clicks it.
#
# @param page [Page] Page object.
# @param target [String] Keyward of the target.
# @return [Promise] Promise object.
search_and_click = (page, target) ->
  page.evaluate ->
    document.body.innerHTML
  .then (html) ->
    $ = cheerio.load html
    href = $("a").filter ->
      name = $("img", @).attr "alt"
      name.includes(target) or target.includes(name)
    .attr "href"

    script = "function() {" + href.substring("javaScript:".length) + ";}"
    page.evaluateJavaScript script


# List up items which associated with a given keyword.
#
# @param page [Page] Page object.
# @param keywork [String] keyword which is a file name of gif file w/o
#   extentions.
# @return [Promise] Promise object.
list_up = (page, keyword) ->
  page.evaluate ->
    document.body.innerHTML
  .then (html) ->
    $ = cheerio.load html
    $("a").map ->
      $("img[src=\"image/#{keyword}.gif\"]", @).attr "alt"
    .toArray()
    .filter (v) ->
      v isnt IGNORED_KEYWORD


# Trim a given string.
#
# @param str [String] a string.
# @return [String] the trimmed string.
trim = (str) ->
  str.replace /^\s+|\s+$/g, ""


# Return a status message from a src url.
#
# @param value [String] a src url.
# @return [String] status message.
check_status = (value) ->
  switch value
    when SRC_CLOSED
      STATUS.CLOSED
    when SRC_OCCUPIED
      STATUS.OCCUPIED
    when SRC_AVAILABLE
      STATUS.AVAILABLE
    when SRC_MAINTENANCE
      STATUS.MAINTENANCE
    when SRC_OUT_OF_DATE
      STATUS.OUT_OF_DATE


module.exports =

  # Returns a list of areas in Fukuoka city.
  #
  # @return [Promise] which returns a list of areas in Fukuoka city.
  area: ->

    run (page) ->

      generate_common_tasks page
      .concat [
        url: AREA_URL
        action: ->
          list_up page, "bw_tiikiimg"
      ]

  # Returns a list of buildings in a given area.
  #
  # @param area [String] name of the area.
  # @return [Promise] which returns a list of buildings in the area.
  building: (area) ->

    run (page) ->

      generate_common_tasks page
      .concat [
        url: AREA_URL
        action: ->
          search_and_click page, area
      ,
        url: BUILDING_URL
        action: ->
          list_up page, "bw_buildingimg"
      ]

  # Returns a list of institutions in a given area and building.
  #
  # @param area [String] name of the area.
  # @param building [String] name of the building.
  # @return [Promise] which returns a list of institutions.
  institution: (area, building) ->

    run (page) ->

      generate_common_tasks page
      .concat [
        url: AREA_URL
        action: ->
          search_and_click page, area
      ,
        url: BUILDING_URL
        action: ->
          search_and_click page, building
      ,
        url: INSTITUTION_URL
        action: ->
          list_up page, "bw_institutionimg"
      ]

  # Search reservation statuses of a given institution in a given date.
  #
  # @param area [String] area name obtained by area method.
  # @param building [String] building name obtained by building method.
  # @param institution [String] institution name obtained by institution method.
  # @param year [Integer] Year.
  # @param month [Integer] Month.
  # @param day [Integer] Day.
  # @return [Promise] which returns the result via then method.
  status: (area, building, institution, year, month, day) ->

    run (page) ->

      tasks = generate_common_tasks page
      .concat [
        url: AREA_URL
        action: ->
          search_and_click page, area
      ,
        url: BUILDING_URL
        action: ->
          search_and_click page, building
      ,
        url: INSTITUTION_URL
        action: ->
          search_and_click page, institution
      ]

      today = new Date()
      if year isnt today.getFullYear() or month isnt today.getMonth()+1
        tasks.push
          url: DAY_WEEK_URL
          action: ->
            page.evaluate ->
              document.body.innerHTML
            .then ->
              new Promise (resolve, reject) ->
                page.evaluateJavaScript """
                  function(){
                    moveCalender(
                    (_dom == 3) ?
                    document.layers['disp'].document.formCommonSrchDayWeekAction
                    : document.formCommonSrchDayWeekAction,
                    gRsvWTransInstSrchDayWeekAction, #{year}, #{month});}"""
                .then ->
                  setTimeout resolve, WAITING_TIME
                .catch (reason) ->
                  reject reason

      tasks.concat [
        url: DAY_WEEK_URL
        action: ->
          search_and_click page, day.toString()
          .then ->
            page.evaluate ->
              action = if window._dom is 3
                document.layers['disp'].document.formCommonSrchDayWeekAction
              else
                document.formCommonSrchDayWeekAction
              window.sendSelectDay action, gRsvWInstSrchVacantAction, 1
      ,
        url: RESULT_URL
        action: ->
          page.evaluate ->
            document.body.innerHTML
          .then (html) ->
            $ = cheerio.load html
            table = $("""#disp > center > table:nth-child(5) >
              tbody:nth-child(3) > tr:nth-child(3) > td:nth-child(2) >
              center > table""")

            res = {}
            if table.length isnt 0
              header = $("tr", table).first()
              dates = header.children().map ->
                trim $(@).text()
              .toArray().slice 1

              header.nextAll().each ->
                left_item = $(@).children().first()

                label = trim left_item.text()
                left_item.nextAll().each (i) ->
                  unless dates[i] of res
                    res[dates[i]] = {}

                  res[dates[i]][label] = check_status(
                    $(@).children().attr("src"))

            else
              table = $("""#disp > center > table:nth-child(5) >
                tbody:nth-child(3) > tr > td:nth-child(2) > center > table""")

              header = $("tr", table).first()
              dates = header.children().map ->
                trim $(@).text()
              .toArray().slice 1

              header.nextAll().each ->
                left_item = $(@).children().first()

                label = trim left_item.text()
                res[label] = {}

                left_item.nextAll().each (i) ->
                  unless dates[i] of res[label]
                    res[label][dates[i]] = {}

                  status = null
                  $(@).contents().each ->
                    switch @.tagName
                      when "img"
                        status = check_status $(@).attr("src")

                      when null
                        time = trim $(@).text()
                        if time.length isnt 0
                          res[label][dates[i]][time] = status

            return res
      ]

  # Constants of status.
  STATUS: STATUS
