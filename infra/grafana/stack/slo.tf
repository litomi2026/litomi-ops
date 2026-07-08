# Availability SLOs for the two request-serving services, via the Grafana SLO app.
#
# These exist so paging rests on an explicit error budget instead of App
# Observability's auto-baselined latency/anomaly assertions. At this traffic
# (~5 rps api, ~1.7 rps web) those assertions are statistical noise — a single
# slow or failed request skews a percentile or ratio — and they route to the
# Asserts insight processor, not to anyone. A burn-rate alert on a budget is the
# signal that actually warrants attention.
#
# Bad = server-side failure only (5xx / span error). Client errors (4xx) and
# rate-limited requests (429) stay outside the budget, and health/readiness
# probes are dropped from the denominator so probe traffic neither inflates nor
# dilutes the ratio.
#
# The SLI source differs per service because their telemetry does. litomi-api
# (Hono on Bun) emits native OTel HTTP server metrics with an exact
# http.response.status_code, so its SLI is 5xx-precise. litomi-web (Next.js /
# @vercel/otel) emits no HTTP server metric — its only request signal is
# trace-derived span metrics, so its SLI is span-error based (STATUS_CODE_ERROR
# is the server span's failure status, ~5xx/uncaught).
#
# Burn-rate alerts inherit the root notification policy and reach Discord.

locals {
  # The stack's hosted Prometheus/Mimir datasource. The SLO app writes its
  # recording and alert rules here.
  slo_destination_datasource_uid = "grafanacloud-prom"

  # k8s liveness/readiness/startup probes are not user traffic.
  api_probe_routes = "/health|/api/health|/ready|/startup"
  web_probe_spans  = "GET /health|GET /ready|GET /startup|GET /api/health"

  # Rolling budget window and target. Generous on purpose while volume is low;
  # tighten as real traffic grows.
  slo_objective = 0.995
  slo_window    = "28d"
}

resource "grafana_slo" "api_availability" {
  name        = "litomi-api availability"
  description = "Fraction of litomi-api requests not served as 5xx, excluding health probes and 429s."

  query {
    type = "freeform"
    freeform {
      query = <<-EOT
        sum(rate(http_server_request_duration_seconds_count{service_name="litomi-api", http_route!~"${local.api_probe_routes}", http_response_status_code!="429", http_response_status_code!~"5.."}[$__rate_interval]))
        /
        sum(rate(http_server_request_duration_seconds_count{service_name="litomi-api", http_route!~"${local.api_probe_routes}", http_response_status_code!="429"}[$__rate_interval]))
      EOT
    }
  }

  objectives {
    value  = local.slo_objective
    window = local.slo_window
  }

  destination_datasource {
    uid = local.slo_destination_datasource_uid
  }

  label {
    key   = "service"
    value = "litomi-api"
  }
  label {
    key   = "sli"
    value = "availability"
  }

  alerting {
    fastburn {
      label {
        key   = "severity"
        value = "critical"
      }
      annotation {
        key   = "summary"
        value = "litomi-api is burning its availability budget fast."
      }
    }
    slowburn {
      label {
        key   = "severity"
        value = "warning"
      }
      annotation {
        key   = "summary"
        value = "litomi-api is burning its availability budget slowly."
      }
    }
  }
}

resource "grafana_slo" "web_availability" {
  name        = "litomi-web availability"
  description = "Fraction of litomi-web server spans without an error status, excluding health probes."

  query {
    type = "freeform"
    freeform {
      query = <<-EOT
        sum(rate(traces_spanmetrics_calls_total{service="litomi-web", span_kind="SPAN_KIND_SERVER", span_name!~"${local.web_probe_spans}", status_code!="STATUS_CODE_ERROR"}[$__rate_interval]))
        /
        sum(rate(traces_spanmetrics_calls_total{service="litomi-web", span_kind="SPAN_KIND_SERVER", span_name!~"${local.web_probe_spans}"}[$__rate_interval]))
      EOT
    }
  }

  objectives {
    value  = local.slo_objective
    window = local.slo_window
  }

  destination_datasource {
    uid = local.slo_destination_datasource_uid
  }

  label {
    key   = "service"
    value = "litomi-web"
  }
  label {
    key   = "sli"
    value = "availability"
  }

  alerting {
    fastburn {
      label {
        key   = "severity"
        value = "critical"
      }
      annotation {
        key   = "summary"
        value = "litomi-web is burning its availability budget fast."
      }
    }
    slowburn {
      label {
        key   = "severity"
        value = "warning"
      }
      annotation {
        key   = "summary"
        value = "litomi-web is burning its availability budget slowly."
      }
    }
  }
}
