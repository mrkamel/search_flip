
# CHANGELOG

## v3.9.0

* Allow to configure the elasticsearch version no matter which elasticsearch
  version is actually in use. The version information is needed to support
  version dependent features. Please note that manually configuring the version
  is usually not need as the version by default is determined by sending one
  request to elasticsearch.

```ruby
SearchFlip::Config[:version] = { number: "8.1.1" }
SearchFlip::Config[:version] = { number: "2.13", distribution: "opensearch" }
```

## v3.8.0

* Support Opensearch 1.x and 2.x

## v3.7.2

* Fix wrong AWS signatures by generating the json before passing it to http-rb

## v3.7.1

* Fix thread-safety issue of http-rb

## v3.7.0

* Add `SearchFlip::Connection#bulk` to allow more clean bulk indexing to
  multiple indices at once

## v3.6.0

* Support Elasticsearch v8

## v3.5.0

* Add `SearchFlip::Criteria#http_timeout` to allow specifying timeouts on
  a query level

## v3.4.0

* Expose `Http#timeout` via `SearchFlip::HTTPClient`

## v3.3.0

* Update httprb
* Changed oj default options
* Allow to set oj json options

## v3.2.1

* Fix `refresh` having a empty body breaking in elasticsearch 7.11

## v3.2.0

* Fix `index_scope` not being passed in `each_record` without block
* Added `SearchFlip::Criteria#match_none`

## v3.1.2

* Fix ignored false value for source when merging criterias

## v3.1.1

* Make `SearchFlip::Result.from_hit` work with the `_source` being disabled

## v3.1.0

* Added plugin support in `SearchFlip::HTTPClient`
* Added `SearchFlip::AwsSigv4Plugin` to be able to use AWS Elasticsearch with
  signed requests

## v3.0.0

* Added `Criteria#to_query`, which returns a raw query including all queries
  and filters, including the post filters
* Added `Criteria#all`
* [BREAKING] Support for elasticsearch 1.x has been removed
* [BREAKING] No longer pass multiple arguments to `#must`, `#must_not`,
  `#filter`, `#should`, `#post_must`, `#post_must_not`, `#post_filter`, and
  `#post_should`. Pass an array of arguments instead: `.post_must([...])`
* [BREAKING] `#should` and `#post_should` is now equivalent to
  `.must(bool: { should: ... })` and `.post_must(bool: { should: ... })`,
* [BREAKING] `#unscope` is removed
* [BREAKING] `SearchFlip::Connection#get_aliases` no longer returns a
  Hashie::Mash, but a raw Hash as was already stated in the docs
* `#post_where` and  `#post_where_not` now handle `nil` values as well:
  `.post_where_not(title: nil)` with `exists/exists not` filters
* `Connection#cat_indices/get_indices` now accepts additional parameters
* `Connection#freeze_index`, `Connection#unfreeze_index`, `Index#freeze_index`
   and `Index#unfreeze_index` added
* Added `SearchFlip::Result.from_hit`
* Added support for `source`, `sort`, `page`, `per`, `paginate`, `explain`, and
  `highlight` to aggregations
* Added support for instrumentation

## v2.3.2

* Remove ruby 2.7 warnings

## v2.3.1

* Make `search_flip` work with hashie 4.0.0

## v2.3.0

* [DEPRECATED] `SearchFlip::Criteria#should` is deprecated and will become
  equivalent to `.must(bool: { should: ... })` in `search_flip` 3
* Added `SearchFlip::Criteria#explain`

## v2.2.0

* [DEPRECATED] `SearchFlip::Criteria#unscope` is deprecated and will be removed
  in `search_flip` 3
* Added `SearchFlip::Criteria#track_total_hits`

## v2.1.0

## v2.0.0

* Added `SearchFlip::Connection`
* [BREAKING] Changed `SearchFlip::Index.base_url` to `SearchFlip::Index.connection`
* [BREAKING] Changed `SearchFlip.version` to `SearchFlip::Connection#version`
* [BREAKING] Changed `SearchFlip.aliases` to `SearchFlip::Connection#update_aliases`
* [BREAKING] Changed `SearchFlip.msearch` to `SearchFlip::Connection#msearch`
* [BREAKING] Removed `base_url` param from `SearchFlip::Critiera#execute`
* [BREAKING] `SearchFlip::Index.index_name` no longer defaults to `SearchFlip::Index.type_name`
* [BREAKING] No longer include the type name in `SearchFlip::Index.mapping`
* Added `SearchFlip::Connection#get_aliases`
* Added `SearchFlip::Connection#get_indices`
* Added `SearchFlip::Connection#alias_exists?`
* Added `SearchFlip::Index#with_settings` and `SearchFlip::Criteria#with_settings`
* Added `SearchFlip::Aggregation#merge`
* Added `bulk_max_mb` config and option
* Added `SearchFlip::Index.analyze`
* Added `SearchFlip::Criteria#preference`
* Added `SearchFlip::Criteria#search_type`
* Added `SearchFlip::Criteria#routing`
* Added `SearchFlip::Index.open_index` and `SearchFlip::Index.close_index`
* Added `SearchFlip::Index.mget`

## v1.1.0

* Added `Criteria#find_results_in_batches` to scroll through the raw results
* Fixed bug in `Criteria#find_in_batches` which possibly stopped scrolling too early
* Added delegation for `should`, `should_not`, `must` and `must_not`
* Migrated To FactoryBot

