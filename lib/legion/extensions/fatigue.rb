# frozen_string_literal: true

require 'legion/extensions/fatigue/version'
require 'legion/extensions/fatigue/helpers/constants'
require 'legion/extensions/fatigue/helpers/energy_model'
require 'legion/extensions/fatigue/helpers/fatigue_store'
require 'legion/extensions/fatigue/runners/fatigue'

module Legion
  module Extensions
    module Fatigue
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
