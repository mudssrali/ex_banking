import Config

# Rate Limiter configuration
config :ex_banking,
  max_requests: 10,
  rate_units: :seconds,
  sweep_rate: 60,
  ets_table: :rater_limiter_requests
