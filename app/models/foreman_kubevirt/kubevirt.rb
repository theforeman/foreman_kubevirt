require 'foreman/exception'

module ForemanKubevirt
  class Kubevirt < ComputeResource
    alias_attribute :hostname, :url
    alias_attribute :token, :password
    alias_attribute :namespace, :user
    #alias_attribute :certificate_path, :uuid

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
    rescue => e
      errors[:base] << e.message
    end

    def create_vm(args = {})
      # TODO implement this
    end

    protected

    # TODO: Add SSL support
    def client
      return @client if @client

      server_parts = hostname.split(':')
      address = server_parts[0]
      port = server_parts[1] || 443

      @client ||= Fog::Compute.new(
        :provider            => "kubevirt",
        :kubevirt_hostname   => address,
        :kubevirt_port       => port,
        :kubevirt_namespace  => namespace || 'default',
        :kubevirt_token      => token,
        :kubevirt_log        => nil,
      )
    rescue => e
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
