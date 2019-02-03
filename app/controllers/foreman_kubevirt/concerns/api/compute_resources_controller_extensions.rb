module ForemanKubevirt
 module Concerns
    module Api::ComputeResourcesControllerExtensions
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

      extend ActiveSupport::Concern

      included do
        include ApiPieExtensions

        def create
          @compute_resource = ComputeResource.new_provider(compute_resource_params)
          @compute_resource.test_connection
          process_response @compute_resource.save
        end

        def update
          process_response @compute_resource.update_attributes(compute_resource_params)
        end
      end
    end
  end
end
