# frozen_string_literal: true

module DogBiscuits
  module Importers
    class Authority
      attr_reader :authority
      attr_reader :authority_name

      def initialize(authority_name)
        @authority_name = authority_name
        @authority = Qa::LocalAuthority.find_or_create_by(name: authority_name) if valid_authority?
      end

      def valid_authority?
        true if Qa::Authorities::Local.subauthority_for(@authority_name)
      rescue Qa::InvalidSubAuthority
        Rails.logger.error("This sub-authority is not registered: #{@authority_name}")
        false
      end

      # Create an authority record in the given local authority
      #
      # @param label [String] the label
      # @param uri [String] the uri, optional
      def create_record(label, uri = nil)
        uri = construct_uri(label) if uri.blank?
        Qa::LocalAuthorityEntry.create(local_authority: @authority,
                                       label: cleanup_label(label),
                                       uri: uri)
      rescue ActiveRecord::RecordNotUnique
        Rails.logger.warn("Duplicate record: #{label}")
      end

      private

        # Replace &amp; with &
        #
        # @param label [String] the label for cleanup
        # @return [String] cleaned up label
        def cleanup_label(label)
          label.gsub('&amp;', '&')
        end

        # Create a version of the label for use as a uri:
        #   replace all non-alphanumeric characters with whitespace
        #   trim to 50 characters and replace whitespace with a dash
        #
        # @param label [String] the label for uri-ification
        # @return [String] uri-ified label
        def uri_ifiy_label(label)
          cleanup_label(label).gsub(/[^\w\s\d]/, ' ')[0..50].parameterize
        end

        # Create a default URI for the term
        #
        # @param label [String] the label for cleanup
        # @return [String] cleaned up label
        def construct_uri(label)
          hostname = `hostname`.delete("\n")
          hostname = "example.com" if hostname.include?('localhost')
          "http://#{hostname}/#{@authority_name}/#{uri_ifiy_label(label)}"
        end
    end
  end
end
