# frozen_string_literal: true

class DbPlaceNote < ActiveRecord::Base
  belongs_to :db_related_place
end
