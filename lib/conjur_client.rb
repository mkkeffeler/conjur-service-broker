require 'conjur-api'
require 'openssl'

class ConjurClient

  class ConjurAuthenticationError < RuntimeError
  end

  class << self
    def api
      ConjurClient.new.api(appliance_url)
    end

    def v4_host_factory_id
      if policy == "root"
        "#{account}:host_factory:apps"
      else
        "#{account}:host_factory:#{policy}/#{policy}-apps"
      end
    end

    def v5?
      version == 5
    end

    def version
      (ENV['CONJUR_VERSION'] || 5).to_i
    end

    def account
      ENV['CONJUR_ACCOUNT']
    end

    def authn_api_key
      ENV['CONJUR_AUTHN_API_KEY']
    end

    def authn_login
      ENV['CONJUR_AUTHN_LOGIN']
    end

    def login_host_id
      authn_login.sub /^host\//, "" if login_is_host?
    end

    def login_is_host?
      authn_login.include?("host\/")
    end

    def appliance_url
      ENV['CONJUR_APPLIANCE_URL']
    end

    def application_conjur_url
      ENV['CONJUR_FOLLOWER_URL'] || appliance_url
    end

    def policy
      ENV['CONJUR_POLICY'] || 'root'
    end

    def ssl_cert
      ENV['CONJUR_SSL_CERTIFICATE'] unless ENV['CONJUR_SSL_CERTIFICATE'].blank?
    end

    def platform
      platform_annotation = ""
      if !login_host_id.nil?
        host = api.resource("#{account}:host:#{login_host_id}")
        JSON.parse(host.attributes["annotations"].to_json).each do |annotation|
          platform_annotation = annotation["value"] if annotation["name"] == "platform"
        end
      end
      
      return platform_annotation
    end
  end

  def api(appliance_url)
    Conjur.configure do |config|
      config.account = ConjurClient.account
      config.appliance_url = appliance_url
      config.ssl_certificate = ConjurClient.ssl_cert
      config.version = ConjurClient.version
    end

    Conjur.configuration.apply_cert_config!

    Conjur::API.new_from_key ConjurClient.authn_login,
                             ConjurClient.authn_api_key
  end
end
