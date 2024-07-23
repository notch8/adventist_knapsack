# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource ExamPaperResource`
require 'rails_helper'
require 'hyrax/specs/shared_specs/indexers'

RSpec.describe ExamPaperResourceIndexer do
  let(:indexer_class) { described_class }
  let(:resource) { ExamPaperResource.new }

  it_behaves_like 'a Hyrax::Resource indexer'
end