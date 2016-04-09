phantom = require "phantom"
cheerio = require "cheerio"

ROOT_URL = "https://www.comnet-fukuoka.jp/web/"

generate_tasks = (instance, page) ->
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
      page.render "test.png"
      page.close()
      instance.exit()
  ]


phantom.create().then (ph) ->

  ph.createPage().then (page) ->

    wait_moved_to = (url) ->
      new Promise (resolve, _) ->
        do checker = ->
          page.property("url").then (res) ->
            res = res.split(";")[0]
            if res is url
              resolve res
            else
              setTimeout checker, 1000

    page.open(ROOT_URL)
      .then ->
        tasks = generate_tasks(ph, page)
        new Promise (resolve, _) ->
          do runner = ->
            t = tasks.shift()
            console.log "move to", t.url
            wait_moved_to(t.url).then(t.action).then ->
              if tasks.length isnt 0
                runner()
              else
                resolve()
