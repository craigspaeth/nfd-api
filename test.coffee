require('zombie').visit 'http://3.hidemyass.com/', { runScripts: false }, (err, browser) =>
  browser
    .fill('#proxyurlinput', 'http://nybits.com')
    .pressButton '#gobutton', ->
      browser.wait ->
        console.log browser.location.href