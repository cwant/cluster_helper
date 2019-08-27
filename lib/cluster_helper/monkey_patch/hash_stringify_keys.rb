unless Hash.instance_methods.include?(:stringify_keys)
  class Hash
    def stringify_keys
      Hash[map { |k, h| [k.to_s, h] }]
    end
  end
end
