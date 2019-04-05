module FogExtensions
  module Kubevirt
    module Network
      extend ActiveSupport::Concern

      def id
        name
      end
    end
  end
end
