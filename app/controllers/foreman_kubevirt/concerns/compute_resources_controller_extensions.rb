module ForemanKubevirt
  module Concerns
    module ComputeResourcesControllerExtensions
      extend ActiveSupport::Concern

      # rubocop:disable Rails/LexicallyScopedActionFilter
      included do
        before_action :normalize_ca_cert, only: %i[create update test_connection]
      end
      # rubocop:enable Rails/LexicallyScopedActionFilter

      private

      # Rails form handles empty string and nil as same,
      # so we need to normalize the ca_cert the verify_tls parameter.
      def normalize_ca_cert
        case params[:verify_tls]
        when 'disable'
          params[:compute_resource][:ca_cert] = nil
        when 'system'
          params[:compute_resource][:ca_cert] = ''
        end
      end
    end
  end
end
