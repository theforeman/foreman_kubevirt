module FogExtensions
  module Kubevirt
    module Volume
      extend ActiveSupport::Concern

      attr_accessor :storage_class
      attr_accessor :capacity

      def id
        name
      end
    end
  end
end
