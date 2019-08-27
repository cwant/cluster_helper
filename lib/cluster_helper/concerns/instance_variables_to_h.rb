module InstanceVariablesToH
  def instance_variables_to_h
    Hash[instance_variables.map do |var|
           value = instance_variable_get(var)
           key = var.to_s.gsub(/^@/, '').to_sym
           key, value = yield(key, value) if block_given?
           [key, value]
         end.compact]
  end
end
