# frozen_string_literal: true

module FogExtensions
  module Kubevirt
    module Volume
      extend ActiveSupport::Concern
      def bootable
        boot_order == 1
      end

      def id
        name
      end
    end
  end
end
