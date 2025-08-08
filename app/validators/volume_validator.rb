# frozen_string_literal: true

class VolumeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value[:volumes_attributes].present?
      value[:volumes_attributes].each do |_, attrs|
        if attrs.key?('capacity') && attrs.key?('storage_class') && (attrs['capacity'].to_s.empty? || /\A\d+G?\Z/.match(attrs['capacity'].to_s).nil?)
          record.errors.add(attribute, _('Volume size %s is not valid') % attrs['capacity'])
        end
      end
    end
  end
end
