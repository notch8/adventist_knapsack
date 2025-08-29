# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CatalogController do
  describe '.blacklight_config' do
    subject(:blacklight_config) { described_class.blacklight_config }

    its(:search_builder_class) { is_expected.to eq(AdvSearchBuilder) }

    describe 'solr dictionaries' do
      it 'does not specified spellcheck.dictionaries' do
        # rubocop:disable Layout/LineLength
        expect(blacklight_config.search_fields).to(be_none { |_field, config| config&.solr_parameters&.key?('spellcheck.dictionaries'.to_sym) })
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
