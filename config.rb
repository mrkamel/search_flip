
module ElasticSearch
  Config = {
    :index => "#{Rails.application.class.parent_name.underscore}_#{Rails.env}",
    :base_url => "http://127.0.0.1:9200",
    :bulk_limit => 1_000
  }
end

