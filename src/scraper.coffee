phantom = require "phantom"
cheerio = require "cheerio"

ROOT_URL = "https://www.comnet-fukuoka.jp/web/"


# Execute a given tasks via PhantomJS.
#
# @param generator [Function] takes a page object and generates tasks.
# @return [Promise] which will pass the result.
run = (generator) ->

  new Promise (resolve, _) ->

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


# Generate common tasks.
#
# Such tasks are for skipping default pages.
#
# @param page [Page] Page object.
# @return [Array] array of tasks which contain url and action.
generate_common_tasks = (page) -> [
  url: "https://www.comnet-fukuoka.jp/web/rsvWTransUserAttestationAction.do"
  action: ->
    page.evaluate ->
      action = if window._dom is 3
        document.layers['disp'].document.formWTransInstSrchVacantAction
      else
        document.formWTransInstSrchVacantAction
      window.doAction action, gRsvWTransInstSrchVacantAction
,
  url: "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchVacantAction.do"
  action: ->
    page.evaluate ->
      action = if window._dom is 3
        document.layers['disp'].document.formWTransInstSrchAreaAction
      else
        document.formWTransInstSrchAreaAction
      window.doAction action, gRsvWTransInstSrchAreaAction
]


module.exports =

  # Returns a list of wards in Fukuoka city.
  #
  # @return [Promise] which returns a list of wards in Fukuoka city.
  wards: ->

    run (page) ->

      tasks = generate_common_tasks page
      tasks.push
        url: "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchAreaAction.do"
        action: ->
          page.evaluate ->
            document.body.innerHTML
          .then (html) ->
            $ = cheerio.load html
            $("a").map ->
              $("img[src=\"image/bw_tiikiimg.gif\"]", @).attr "alt"
            .toArray()
      tasks

  search: (ward, place, room) ->

    run (page) ->

      search_and_move = (target) ->
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

      [
        url: "https://www.comnet-fukuoka.jp/web/rsvWTransUserAttestationAction.do"
        action: ->
          page.evaluate ->
            action = if window._dom is 3
              document.layers['disp'].document.formWTransInstSrchVacantAction
            else
              document.formWTransInstSrchVacantAction
            window.doAction action, gRsvWTransInstSrchVacantAction
      ,
        url: "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchVacantAction.do"
        action: ->
          page.evaluate ->
            action = if window._dom is 3
              document.layers['disp'].document.formWTransInstSrchAreaAction
            else
              document.formWTransInstSrchAreaAction
            window.doAction action, gRsvWTransInstSrchAreaAction
      ,
        url: "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchAreaAction.do"
        action: ->
          search_and_move ward
      ,
        url: "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchBuildAction.do"
        action: ->
          search_and_move place
      ,
        url: "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchInstAction.do"
        action: ->
          search_and_move room
      ,
        url: "https://www.comnet-fukuoka.jp/web/rsvWTransInstSrchDayWeekAction.do"
        action: ->
          page.evaluate ->
            document.body.innerHTML
          .then (html)->
            console.log html
            page.render "test.png"
      ]
