module FogExtensions
  module Kubevirt
    module Volume
      extend ActiveSupport::Concern

      def id
        name
      end
    end
  end
end
