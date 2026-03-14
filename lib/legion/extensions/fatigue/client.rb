# frozen_string_literal: true

require 'legion/extensions/fatigue/helpers/constants'
require 'legion/extensions/fatigue/helpers/energy_model'
require 'legion/extensions/fatigue/helpers/fatigue_store'
require 'legion/extensions/fatigue/runners/fatigue'

module Legion
  module Extensions
    module Fatigue
      class Client
        include Runners::Fatigue

        attr_reader :fatigue_store

        def initialize(fatigue_store: nil, **)
          @fatigue_store = fatigue_store || Helpers::FatigueStore.new
        end
      end
    end
  end
end
