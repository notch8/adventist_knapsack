# frozen_string_literal: true

# Pin gems that resolve to incompatible versions when bundled from the project
# root (which has no Gemfile.lock). Remove these once upstream Hyku PRs land:
#   - blacklight_advanced_search 8.0 adds :facets_for_advanced_search_form to
#     the default processor chain, breaking adv_search_builder_spec
#   - json 2.13+ raises TypeError on JSON.load(Hash), breaking account_settings
#     factory setup in tests
override_gem 'blacklight_advanced_search', '~> 7.0'
ensure_gem 'json', '~> 2.12.2'

# OVERRIDE Bulkrax v9.3.0, backporting v9.5.2 (the version Hyku v7.2.2 ships):
# picks up a dependency fix ahead of hyrax-webapp's own constraint. Remove
# once the submodule vendors a Hyku release at or past v7.2.2.
override_gem "bulkrax", "~> 9.5.2"

# OVERRIDE Blacklight v7.43.0: its new Solr-runtime logging reads
# ActiveSupport::IsolatedExecutionState, which doesn't exist before Rails 7.0
# (we're on 6.1), raising NameError on every request. Remove once we're on
# Rails 7+, or once a Blacklight release restores Rails 6.1 support.
override_gem 'blacklight', '~> 7.42.0'
