# frozen_string_literal: true

# OVERRIDE Hyrax 5 to customize file_set_args for thumbnail override
module Hyrax
  module WorkUploadsHandlerDecorator
    private

    ##
    # @api private
    #
    # @return [Hash{Symbol => Object}]
    def file_set_args(file, file_set_params = {})
      { depositor: file.user.user_key,
        creator: file.user.user_key,
        date_uploaded: file.created_at,
        date_modified: Hyrax::TimeService.time_in_utc,
        label: file.uploader.filename,
        title: file.uploader.filename,
        override_default_thumbnail: file_set_extra_params(file)["override_default_thumbnail"] }.merge(file_set_params)
    end
  end
end

Hyrax::WorkUploadsHandler.prepend(Hyrax::WorkUploadsHandlerDecorator)
