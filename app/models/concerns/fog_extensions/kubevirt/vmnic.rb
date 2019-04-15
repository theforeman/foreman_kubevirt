module FogExtensions
  module Kubevirt
    module VmNic
      extend ActiveSupport::Concern
      attr_accessor  :id

      def id
        name
      end
    end
  end
end
