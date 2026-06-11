# frozen_string_literal: true

# Pin gems that resolve to incompatible versions when bundled from the project
# root (which has no Gemfile.lock). Remove these once upstream Hyku PRs land:
#   - blacklight_advanced_search 8.0 adds :facets_for_advanced_search_form to
#     the default processor chain, breaking adv_search_builder_spec
#   - json 2.13+ raises TypeError on JSON.load(Hash), breaking account_settings
#     factory setup in tests
override_gem 'blacklight_advanced_search', '~> 7.0'
ensure_gem 'json', '~> 2.12.2'
