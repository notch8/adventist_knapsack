# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource PublishedWorkResource`
#
# @see https://github.com/samvera/hyrax/wiki/Hyrax-Valkyrie-Usage-Guide#forms
# @see https://github.com/samvera/valkyrie/wiki/ChangeSets-and-Dirty-Tracking
class PublishedWorkResourceForm < Hyrax::Forms::ResourceForm(PublishedWorkResource)
  # Commented out basic_metadata because these terms were added to published_work_resource so we can customize it.
  include Hyrax::FormFields(:basic_metadata)
  include Hyrax::FormFields(:adl_metadata)
  include Hyrax::FormFields(:published_work_resource)
  include Hyrax::FormFields(:bulkrax_metadata)
  include Hyrax::FormFields(:with_pdf_viewer)
  include Hyrax::FormFields(:with_video_embed)
  include Hyrax::FormFields(:slug_metadata)
  include VideoEmbedBehavior::Validation
  include(SlugBugValkyrie)
  # Define custom form fields using the Valkyrie::ChangeSet interface
  #
  # property :my_custom_form_field

  # if you want a field in the form, but it doesn't have a directly corresponding
  # model attribute, make it virtual
  #
  # property :user_input_not_destined_for_the_model, virtual: true
end
