module FogExtensions
  module Kubevirt
    module Volume
      extend ActiveSupport::Concern

      attr_accessor :storage_class
      attr_accessor :capacity

      def capacity
        pvc.requests[:storage] unless pvc.nil?
      end

      def storage_class
        pvc.storage_class unless pvc.nil?
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
