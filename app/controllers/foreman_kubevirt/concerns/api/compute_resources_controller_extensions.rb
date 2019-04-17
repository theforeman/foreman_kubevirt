module ForemanKubevirt
  module Concerns
    module Api
      module ComputeResourcesControllerExtensions
        module ApiPieExtensions
          extend ::Apipie::DSL::Concern
          update_api(:create, :update) do
            param :compute_resource, Hash do
              param :token, String, :desc => N_("Token for KubeVirt only")
              param :hostname, String, :desc => N_("Host name for KubeVirt only")
              param :namespace, String, :desc => N_("Namespace for KubeVirt only")
              param :ca_crt, String, :desc => N_("CA crt for KubeVirt only")
              param :api_port, String, :desc => N_("API port for KubeVirt only")
            end
          end
        end
      end

      extend ActiveSupport::Concern

      included do
        include ApiPieExtensions
      end
    end
  end
end
