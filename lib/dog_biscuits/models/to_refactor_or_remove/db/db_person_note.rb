# frozen_string_literal: true

class DbPersonNote < ActiveRecord::Base
  belongs_to :db_related_agent
end
