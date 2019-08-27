lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cluster_helper/version'

Gem::Specification.new do |spec|
  spec.name = 'cluster_helper'
  spec.version = ClusterHelper::VERSION
  spec.authors = ['Chris Want']
  spec.email = ['cjwant@ualberta.ca']

  spec.summary = 'Making a cluster easier to use'
  spec.files = []
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'pry'
  if RUBY_VERSION < '2.1'
    # Need very specific versions to work with Ruby 2.0
    spec.add_development_dependency 'parallel', '= 1.13.0'
    spec.add_development_dependency 'rubocop', '= 0.50.0'
  else
    spec.add_development_dependency 'rubocop'
  end
end
