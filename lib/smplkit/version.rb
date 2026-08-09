# frozen_string_literal: true

module Smplkit
  # Local-development fallback only. The canonical version of a published gem
  # is stamped into the gem's build-time metadata from the release tag by the
  # gemspec (see +smplkit.gemspec+); +Smplkit.gem_version+ reads that metadata
  # at runtime. This constant is used when the SDK runs from a source
  # checkout that has no installed gem to consult.
  VERSION = "0.0.0"

  # The version of the smplkit gem actually loaded, read from RubyGems
  # package metadata.
  #
  # The release workflow never rewrites +VERSION+ above — the published
  # version exists only in the git tag and, via the gemspec's build-time
  # derivation, in the built gem's serialized specification. An installed gem
  # therefore reports the real release version through +Gem.loaded_specs+,
  # while a plain source checkout falls back to +VERSION+. The +smplkit-sdk+
  # name is the ADR-046 §2.1 fallback gem name.
  #
  # @api private
  # @return [String] the loaded gem's version, or +VERSION+ when the SDK is
  #   not running from an installed gem.
  def self.gem_version
    spec = Gem.loaded_specs["smplkit"] || Gem.loaded_specs["smplkit-sdk"]
    spec ? spec.version.to_s : VERSION
  end

  # The default User-Agent stamped on every outbound request (including the
  # live-updates event stream) when the caller has not supplied their own.
  #
  # The platform sits behind a WAF that rejects requests carrying no
  # User-Agent, and an SDK-identifying value keeps support/telemetry able to
  # attribute traffic to an SDK and version in access logs.
  #
  # @api private
  # @return [String] +smplkit-sdk-ruby/<version>+
  def self.user_agent
    "smplkit-sdk-ruby/#{gem_version}"
  end
end
