unless Array.instance_methods.include?(:to_h)
  class Array
    def to_h
      Hash[self]
    end
  end
end
