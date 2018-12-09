require 'foreman/exception'

module ForemanKubevirt
  class Kubevirt < ComputeResource
    alias_attribute :hostname, :url
    alias_attribute :token, :password
    alias_attribute :namespace, :user

    def ca_cert
      attrs[:ca_cert]
    end

    def ca_cert=(key)
      attrs[:ca_cert] = key
    end

    def capabilities
      [:image]
    end

    def provided_attributes
      super
    end

    def self.provider_friendly_name
      'KubeVirt'
    end

    def to_label
      "#{name} (#{provider_friendly_name})"
    end

    def self.model_name
      ComputeResource.model_name
    end

    def test_connection(options = {})
      super
      connection_details_ok? && client.valid? && client.virt_supported?
    rescue StandardError => e
      errors[:base] << e.message
    end

    def create_vm(args = {})
      # TODO: implement this
    end


    def server_address
      hostname.split(':')[0]
    end

    def server_port
      hostname.split(':')[1] || 443
    end

    protected

    def client
      return @client if @client

      @client ||= Fog::Compute.new(
        :provider            => "kubevirt",
        :kubevirt_hostname   => server_address,
        :kubevirt_port       => server_port,
        :kubevirt_namespace  => namespace || 'default',
        :kubevirt_token      => token,
        :kubevirt_log        => logger,
        :kubevirt_verify_ssl => ca_cert.present?,
        :kubevirt_ca_cert    => ca_cert
      )
    rescue StandardError => e
      if e.message =~ /SSL_connect.*certificate verify failed/ ||
         e.message =~ /Peer certificate cannot be authenticated with given CA certificates/
        raise Foreman::FingerprintException.new(
          N_("The remote system presented a public key signed by an unidentified certificate authority. If you are sure the remote system is authentic, go to the compute resource edit page, press the 'Test Connection' button and submit"),
          ca_cert
        )
      else
        raise e
      end
    end

    private

    def connection_details_ok?
      errors[:url].empty? && errors[:user].empty? && errors[:password].empty?
    end
  end
end
