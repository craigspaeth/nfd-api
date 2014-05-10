{ CronJob } = require 'cron'
{ exec } = require 'child_process'

log = (err, stdout, stderr) ->
  return console.log "FAILED CRON: " + err if err
  console.log 'SUCCESSFUL CRON: ' + stdout

new CronJob '0 */5 * * *', (-> exec "make scrape", log), null, true, 'America/New_York'
new CronJob '00 30 11 * * 1-7', (-> exec "make send-alerts", log), null, true, 'America/New_York'