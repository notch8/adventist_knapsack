# frozen_string_literal: true
# Override Hyrax branch main_before_rails_72
# - find old filesets which don't include generic_type index term.
# - find members using resource_id_ssi or id to support child works

module Hyrax
  module PcdmMemberPresenterFactoryDecorator
    def member_presenters(ids = object.member_ids)
      return enum_for(:member_presenters, ids).to_a unless block_given?

      results = query_docs(ids:)

      ids.each do |id|
        id = id.to_s
        indx = results.index { |doc| id == doc['resource_id_ssi'] || id == doc['fedora_id_ssi'] || id == doc['id'] }
        raise(Hyrax::ObjectNotFoundError, "Could not find an indexed document for id: #{id}") if
          indx.nil?
        hash = results.delete_at(indx)
        yield presenter_for(document: ::SolrDocument.new(hash), ability:)
      end
    end

    private

    def query_docs(generic_type: nil, ids: object.member_ids)
      case generic_type
      when "FileSet"
        docs = super
        return docs unless docs.empty?
        # Fallback to Solr query for older filesets that don't have generic_type index term
        # This can be removed once all filesets are migrated
        Rails.logger.info "Fallback query: no fileset docs found for work #{object.to_param}, looking by model"
        find_by_model(generic_type:, ids:)
      else
        query_works(ids:)
      end
    end

    def find_by_model(generic_type:, ids:)
      query = "{!terms f=id}#{ids.join(',')}"
      query += "{!term f=has_model_ssim}#{generic_type}"

      Hyrax::SolrService
        .post(q: query, rows: 10_000)
        .fetch('response')
        .fetch('docs')
    end

    # Query for works using resource_id_ssi or fedora_id_ssi to support slugs
    def query_works(ids:)
      terms = ids.map { |id| "\"#{id}\"" }.join(' ')
      query = "(id:(#{terms}) OR resource_id_ssi:(#{terms}) OR fedora_id_ssi:(#{terms}))"

      Hyrax::SolrService
        .post(fq: query, rows: 10_000)
        .fetch('response')
        .fetch('docs')
    end
  end
end

Hyrax::PcdmMemberPresenterFactory.prepend Hyrax::PcdmMemberPresenterFactoryDecorator
