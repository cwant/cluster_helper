unless Hash.instance_methods.include?(:stringify_keys)
  class Hash
    def stringify_keys
      Hash[map do |key, value|
             out = if value.is_a?(Hash)
                     value.stringify_keys
                   elsif value.is_a?(Array)
                     value.map { |e| e.is_a?(Hash) ? e.stringify_keys : e }
                   else
                     value
                   end
             [key.to_s, out]
           end]
    end
  end
end
