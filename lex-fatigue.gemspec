# frozen_string_literal: true

require_relative 'lib/legion/extensions/fatigue/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-fatigue'
  spec.version       = Legion::Extensions::Fatigue::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Fatigue'
  spec.description   = 'Cognitive fatigue modeling for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-fatigue'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-fatigue'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-fatigue'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-fatigue'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-fatigue/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-fatigue.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
