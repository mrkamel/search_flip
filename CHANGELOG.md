
# CHANGELOG

## v3.0.0

* [BREAKING] No longer pass multiple arguments to `#must`, `#must_not`,
  `#filter`, `#should`, `#post_must`, `#post_must_not`, `#post_filter`, and
  `#post_should`. Pass an array of arguments instead: `.post_must([...])`
* [BREAKING] `#should` and `#post_should` is now equivalent to
  `.must(bool: { should: ... })` and `.post_must(bool: { should: ... })`,
  respectively.
* [BREAKING] `#unscope` is removed
* `#post_where` and  `#post_where_not` now handle `nil` values as well:
  `.post_where_not(title: nil)` with `exists/exists not` filters

## v2.3.1

* Make search_flip work with hashie 4.0.0

## v2.3.0

* [DEPRECATED] `SearchFlip::Criteria#should` is deprecated and will become
  equivalent to `.must(bool: { should: ... })` in search_flip 3
* Added `SearchFlip::Criteria#explain`

## v2.2.0

* [DEPRECATED] `SearchFlip::Criteria#unscope` is deprecated and will be removed
  in search_flip 3
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

