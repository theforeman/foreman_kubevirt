module FogExtensions
  module Kubevirt
    module Pvc
      extend ActiveSupport::Concern

      def id
        name
      end
    end
  end
end
