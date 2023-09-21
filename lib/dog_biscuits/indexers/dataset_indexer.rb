# frozen_string_literal: true

module DogBiscuits
  class DatasetIndexer < Hyrax::WorkIndexer
    include DogBiscuits::IndexesCommon

    def contributors_to_index
      ['funder']
    end

    # Force the type of certain indexed fields in solr
    # (inspired by
    #   http://projecthydra.github.io/training/deeper_into_hydra/#slide-63,
    #   http://projecthydra.github.io/training/deeper_into_hydra/#slide-64
    #   and discussed at
    #   https://groups.google.com/forum/#!topic/hydra-tech/rRsBwdvh5dE)
    # This is to overcome limitations with solrizer and
    #   "index.as :stored_sortable" always defaulting to string rather
    #   than text type (solr sorting on string fields is case-sensitive,
    #   on text fields it's case-insensitive)
    def do_local_indexing(solr_doc)
      solr_doc['dc_access_rights_tesi'] = object.dc_access_rights.collect { |x| x }
    end
  end
end
