# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work ConferenceItem`
module Hyrax
  # Generated controller for ConferenceItem
  class ConferenceItemsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyku::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::ConferenceItemResource

    # Use a Valkyrie aware form service to generate Valkyrie::ChangeSet style
    # forms.
    self.work_form_service = Hyrax::FormFactory.new

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::ConferenceItemPresenter
  end
end
