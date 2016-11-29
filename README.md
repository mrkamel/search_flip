
# ElasticSearch

[![Build Status](https://secure.travis-ci.org/mrkamel/elastic_search.png?branch=master)](http://travis-ci.org/mrkamel/elastic_search)

## Non-ActiveRecord models

To use with non-ActiveRecord models the model must implement:

* `Model#id`
* `Model.find_each`
* `Model.where(:id => [...])`

TODO replace with

* `Index.record_id`
* `Model.find_each`
* `Index.fetch_records`

## Current ActiveSupport Dependencies

* `Hash#except` (can probably be removed)
* `Module#delegate`
* `Object#present?`
* `Object#blank?`

## TODO

* Highlighting
* Suggestions

