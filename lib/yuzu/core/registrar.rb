
module Yuzu::Registrar

  # Class Register includes routines for storing singletons of objects with a common base class that
  # can be executed as a set.
  class Register
    # Subclasses should redefine `registry` with a unique identifier equal to the name of the class
    # variable that will contain the singletons.
    def self.registry
      :registered
    end
    cattr_reader self.registry

    # Subclasses of the Register should call this method after their definitions to register them 
    # into the registry.
    def self.register(name_to_class={})
      class_var = "@@#{self.registry}".to_sym
      register = class_variable_get(class_var)
      if register.nil?
        class_variable_set(class_var, {})
        register = {}
      end
      name_to_instance = Hash[name_to_class.collect {|name, klass| [name, klass.new]}]
      class_variable_set(class_var, register.merge(name_to_instance))
    end
  end

end

