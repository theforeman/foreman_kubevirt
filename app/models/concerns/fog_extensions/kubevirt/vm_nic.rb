module FogExtensions
  module Kubevirt
    module VMNic
      extend ActiveSupport::Concern
      attr_writer :id

      def id
        name
      end
    end
  end
end
