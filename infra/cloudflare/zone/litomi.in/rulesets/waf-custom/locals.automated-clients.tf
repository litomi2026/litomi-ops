locals {
  automated_user_agent_keywords = [
    "acunetix",
    "aiohttp",
    "axios/",
    "curl/",
    "dart/",
    "dirbuster",
    "ffuf",
    "go-http-client",
    "gobuster",
    "guzzlehttp",
    "headless",
    "headlesschrome",
    "httpie",
    "httpclient",
    "httpx",
    "hydra",
    "java/",
    "libcurl",
    "libwww-perl",
    "masscan",
    "mechanize",
    "nessus",
    "nikto",
    "node-fetch",
    "nuclei",
    "phantomjs",
    "playwright",
    "puppeteer",
    "python-requests",
    "python-urllib",
    "scraper",
    "scrapy",
    "selenium",
    "slimerjs",
    "sqlmap",
    "undici",
    "urllib3",
    "webdriver",
    "wget",
    "wpscan",
    "zgrab",
  ]

  unverified_bot_user_agent_keywords = [
    "bot",
    "crawl",
    "spider",
  ]

  automated_user_agent_expression = join(" ", [
    "(",
    "http.user_agent eq \"\"",
    "or",
    join(" or ", [
      for keyword in local.automated_user_agent_keywords :
      format("lower(http.user_agent) contains \"%s\"", keyword)
    ]),
    "or (",
    "not cf.client.bot",
    "and (",
    join(" or ", [
      for keyword in local.unverified_bot_user_agent_keywords :
      format("lower(http.user_agent) contains \"%s\"", keyword)
    ]),
    ")",
    ")",
    ")",
  ])
}
