module FogExtensions
  module Kubevirt
    module Volume
      extend ActiveSupport::Concern

      attr_writer :storage_class
      attr_writer :capacity

      def capacity
        pvc.requests[:storage] unless pvc.nil?
      end

      def storage_class
        pvc&.storage_class
      end

      def bootable
        boot_order == 1
      end

      def id
        name
      end
    end
  end
end
