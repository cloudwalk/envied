# frozen_string_literal: true

require 'envied/version'
require 'envied/env_proxy'
require 'envied/coercer'
require 'envied/coercer/envied_string'
require 'envied/variable'
require 'envied/configuration'

class ENVied
  class << self
    attr_reader :env, :config
    alias required? env
  end

  def self.require(*args, **options)
    requested_groups = args && !args.empty? ? args : ENV['ENVIED_GROUPS']
    env!(requested_groups, **options)
    error_on_missing_variables!(**options)
    error_on_uncoercible_variables!(**options)

    ensure_spring_after_fork_require(args, **options)
  end

  def self.env!(requested_groups, **options)
    @config = options.fetch(:config) { Configuration.load }
    @env = EnvProxy.new(@config, groups: required_groups(*requested_groups))
  end

  def self.error_on_missing_variables!(**options)
    names = env.missing_variables.map(&:name)
    return unless names.any?

    msg = "The following environment variables should be set: #{names.join(', ')}."
    msg << "\nPlease make sure to stop Spring before retrying." if spring_enabled? && !options[:via_spring]
    raise msg
  end

  def self.error_on_uncoercible_variables!(**options)
    errors = env.uncoercible_variables.map do |v|
      format('%<name>s with %<value>s (%<type>s)', name: v.name, value: env.value_to_coerce(v).inspect, type: v.type)
    end
    return unless errors.any?

    msg = "The following environment variables are not coercible: #{errors.join(', ')}."
    msg << "\nPlease make sure to stop Spring before retrying." if spring_enabled? && !options[:via_spring]
    raise msg
  end

  def self.required_groups(*groups)
    splitter = ->(group) { group.is_a?(String) ? group.split(/ *, */) : group }
    result = groups.compact.map(&splitter).flatten
    result.any? ? result.map(&:to_sym) : [:default]
  end

  def self.ensure_spring_after_fork_require(args, **options)
    return unless spring_enabled? && !options[:via_spring]

    Spring.after_fork { ENVied.require(args, **options.merge(via_spring: true)) }
  end

  def self.springify(&block)
    if defined?(ActiveSupport::Deprecation.warn) && !required?
      ActiveSupport::Deprecation.warn(<<~MSG)
        It's no longer recommended to `ENVied.require` within ENVied.springify's
        block.
      MSG
    end
    if spring_enabled?
      Spring.after_fork(&block)
    else
      block.call
    end
  end

  def self.spring_enabled?
    defined?(Spring) && Spring.respond_to?(:watcher)
  end

  def self.method_missing(method, *args, &block)
    respond_to_missing?(method) ? (env && env[method.to_s]) : super
  end

  def self.respond_to_missing?(method, include_private = false)
    env&.key?(method) || super
  end
end
