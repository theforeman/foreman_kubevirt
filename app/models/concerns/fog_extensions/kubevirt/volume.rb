module FogExtensions
  module Kubevirt
    module Volume
      extend ActiveSupport::Concern
      def bootable
        !boot_order.nil?
      end

      def id
        name
      end
    end
  end
end
