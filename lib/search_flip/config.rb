module SearchFlip
  Config = {
    index_prefix: nil,
    base_url: "http://127.0.0.1:9200",
    bulk_limit: 1_000,
    bulk_max_mb: 100,
    auto_refresh: false,
    instrumenter: NullInstrumenter.new,
    json_options: {
      mode: :custom,
      use_to_json: true,
      time_format: :xmlschema,
      bigdecimal_as_decimal: false
    }
  }
end
