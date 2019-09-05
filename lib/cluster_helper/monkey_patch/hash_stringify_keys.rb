unless Hash.instance_methods.include?(:stringify_keys)
  class Hash
    def stringify_keys
      Hash[map do |key, value|
             [key.to_s,
              value.is_a?(Hash) ? value.stringify_keys : value]
           end]
    end
  end
end
