locals {
  initiator_protected_request_targets = [
    {
      host        = "litomi.in"
      path_prefix = "/api/"
    },
    {
      host        = "stg.litomi.in"
      path_prefix = "/api/"
    },
    {
      host        = "img.litomi.in"
      path_prefix = null
    },
    {
      host        = "img-stg.litomi.in"
      path_prefix = null
    },
    {
      host        = "vercel.litomi.in"
      path_prefix = null
    },
    {
      host        = "vercel-stg.litomi.in"
      path_prefix = null
    },
    {
      host        = "vercel2.litomi.in"
      path_prefix = null
    },
    {
      host        = "vercel2-stg.litomi.in"
      path_prefix = null
    },
  ]

  initiator_protected_request_target_expression = format(
    "(%s)",
    join(" or ", [
      for target in local.initiator_protected_request_targets :
      target.path_prefix == null ?
      format("(http.host eq \"%s\")", target.host) :
      format("((http.host eq \"%s\") and starts_with(http.request.uri.path, \"%s\"))", target.host, target.path_prefix)
      ]
    ),
  )

  trusted_sec_fetch_site_expression = format(
    "any(%s eq \"same-origin\")",
    local.sec_fetch_site_values_expression,
  )

  trusted_request_initiator_origins = [
    "https://litomi.in",
    "https://stg.litomi.in",
  ]

  trusted_request_initiator_origin_expression_set = format("{%s}", join(" ", [
    for origin in local.trusted_request_initiator_origins :
    format("\"%s\"", origin)
  ]))

  trusted_request_origin_expression = format(
    "(has_key(http.request.headers, \"origin\") and lower(http.request.headers[\"origin\"][0]) in %s)",
    local.trusted_request_initiator_origin_expression_set,
  )

  trusted_request_referer_expression = format(
    "(has_key(http.request.headers, \"referer\") and (%s))",
    join(" or ", [
      for origin in local.trusted_request_initiator_origins :
      format(
        "(lower(http.request.headers[\"referer\"][0]) eq \"%s\" or starts_with(lower(http.request.headers[\"referer\"][0]), \"%s/\"))",
        origin,
        origin,
      )
    ]),
  )

  trusted_request_initiator_expression = format(
    "(%s or %s or %s)",
    local.trusted_sec_fetch_site_expression,
    local.trusted_request_origin_expression,
    local.trusted_request_referer_expression,
  )

  untrusted_initiator_protected_request_expression = format(
    "(%s and not %s)",
    local.initiator_protected_request_target_expression,
    local.trusted_request_initiator_expression,
  )

}
