module FogExtensions
  module Kubevirt
    module VmNic
      extend ActiveSupport::Concern
      attr_accessor  :id

      attr_accessor :cni_provider
      attr_accessor :network

      def id
        name
      end
    end
  end
end
