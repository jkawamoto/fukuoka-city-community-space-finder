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
          new Promise (resolve, _) ->
            do checker = ->
              page.property("url").then (res) ->
                res = res.split(";")[0]
                if res is url
                  resolve res
                else
                  setTimeout checker, 1500

        page.open(ROOT_URL)
          .then ->
            tasks = generator page
            new Promise (resolve, _) ->
              do runner = ->
                t = tasks.shift()
                console.log "move to", t.url
                wait_moved_to(t.url).then(t.action).then (res) ->
                  if tasks.length isnt 0
                    runner()
                  else
                    resolve res
                .catch (reason) ->
                  console.log reason

          .then (res) ->
            page.close()
            instance.exit()
            resolve res

          .catch (reason) ->
            console.error reason
            # Clean up.
            page.close()
            ph.exit()
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
      name.includes target or target.includes name
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

  search: (ward, place, room) ->

    run (page) ->

      generate_common_tasks page
      .concat [
        url: AREA_URL
        action: ->
          search_and_click page, ward
      ,
        url: BUILDING_URL
        action: ->
          search_and_click page, place
      ,
        url: INSTITUTION_URL
        action: ->
          search_and_click page, room
      ,
        url: DAY_WEEK_URL
        action: ->
          search_and_click page, 20.toString()
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
            console.log html
            page.render "test.png"
      ]
