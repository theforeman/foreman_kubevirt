module FogExtensions
  module Kubevirt
    module VM
      extend ActiveSupport::Concern

      def ready?
        'running'.casecmp(status || '').zero?
      end
    end
  end
end
