module MethodsToH
  def methods_to_h(methods)
    Hash[methods.map do |key|
           value = send(key)
           key, value = yield(key, value) if block_given?
           [key, value]
         end.compact]
  end
end
