{ CronJob } = require 'cron'
{ spawn } = require 'child_process'

spawnJob = module.exports.spawnJob = (task) ->
  console.log "CRON #{task.toUpperCase()} SPAWNING..."
  job = spawn task.split(' ')[0], task.split(' ').slice(1)
  job.stdout.on 'data', (data) -> console.log "CRON #{task.toUpperCase()} STDOUT: " + data
  job.stderr.on 'data', (data) -> console.log "CRON #{task.toUpperCase()} STDERR: " + data
  job.on 'close', (code) -> console.log "CRON #{task.toUpperCase()} EXITED WITH: #{code}"

module.exports.start = ->
  new CronJob '0 */4 * * *', (-> spawnJob "make scrape-pages"), null, true, 'America/New_York'
  new CronJob '0 */1 * * *', (-> spawnJob "make geocode"), null, true, 'America/New_York'
  new CronJob '0 */1 * * *', (-> spawnJob "make scrape-listings"), null, true, 'America/New_York'
  new CronJob '00 30 11 * * 1-7', (-> spawnJob "make send-alerts"), null, true, 'America/New_York'
  new CronJob '00 30 11 * * 1-7', (-> spawnJob "make drop-old"), null, true, 'America/New_York'