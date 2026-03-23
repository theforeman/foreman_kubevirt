module ForemanKubevirt
  module Concerns
    module Api
      module ComputeResourcesControllerExtensions
        extend ::Apipie::DSL::Concern

        update_api(:create, :update) do
          param :compute_resource, Hash do
            param :token, String, required: true, desc: N_("Token for KubeVirt only")
            param :hostname, String, required: true, desc: N_("Host name for KubeVirt only")
            param :namespace, String, required: true, desc: N_("Namespace for KubeVirt only")
            param :ca_cert, String, required: false, desc: N_("Custom CA cert for KubeVirt only. NIL - Do not verify TLS, empty string - TLS is verified by system CA")
            param :api_port, String, required: true, desc: N_("API port for KubeVirt only")
          end
        end
      end
    end
  end
end
