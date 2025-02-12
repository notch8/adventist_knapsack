# frozen_string_literal: true
HykuKnapsack::Engine.routes.draw do
  mount Hyrax::Engine, at: '/'
  mount IiifPrint::Engine, at: '/'
end
