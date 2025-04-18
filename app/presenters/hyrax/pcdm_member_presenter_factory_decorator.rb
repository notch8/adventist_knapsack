# frozen_string_literal: true
# Override Hyrax branch main_before_rails_72 to find old filesets which don't include generic_type index term.
# Can be removed once all filesets are updated.

module Hyrax
  module PcdmMemberPresenterFactoryDecorator
    private

    def query_docs(generic_type: nil, ids: object.member_ids)
      docs = super
      return docs unless docs.empty?

      Rails.logger.info "Fallback query: no fileset docs found for work #{object.slug}"

      query = "{!terms f=id}#{ids.join(',')}"
      query += "{!term f=has_model_ssim}#{generic_type}" if generic_type

      Hyrax::SolrService
        .post(q: query, rows: 10_000)
        .fetch('response')
        .fetch('docs')
    end
  end
end

Hyrax::PcdmMemberPresenterFactory.prepend Hyrax::PcdmMemberPresenterFactoryDecorator
