module ForemanKubevirt
  module ComputeAttributeExtensions
    extend ActiveSupport::Concern
    included do
      validates :vm_attrs, :volume => true
    end
  end
end
