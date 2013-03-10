# The Registrar module contains mechanisms for registering instances of subclasses of a given
# categorical type, so that we can manage them by name later.
#
# For example, the Filters, which gather metadata-like information about the contents of a given
# file, are subclasses of "Filter", like ImagesFilter, SidebarFilter, etc. These are instantied as
# singletons in a hash contained by the class and can thus be referred to by their key, a short name
# declared by the subclass, e.g. :images, :sidebar, etc. When a WebsiteFile is produced, these
# registered instances can be defined as methods of the WebsiteFile in one swoop.

module Yuzu::Registrar

  # Class Register includes routines for storing singletons of objects with a common base class that
  # can be executed as a set.
  # TODO Stop using inheritance and adopt a more dynamic pattern to mix in these methods.
  class Register
    # Subclasses should redefine `registry` with a unique identifier equal to the name of the class
    # variable that will contain the singletons.
    @@registered = {}
    def self.registry
      :registered
    end
    def self.registered
      @@registered
    end

    # Subclasses of the Register should call this method after their definitions to register them 
    # into the registry.
    def self.register(name_to_class={})
      class_var = "@@#{self.registry}".to_sym

      # Initialize the class variable, e.g. @@registered, in the class.
      register = class_variable_get(class_var)
      if register.nil?
        class_variable_set(class_var, {})
        register = {}
      end

      # Given a {:name => Klass} hash, create a {:name => Instance} hash and remember the instance.
      # But don't instantiate new instances if we already have them around.
      new_instances = {}
      name_to_class.each_pair do |name, klass|
        if not register.has_key?(name)
          name_to_instance = {name => klass.new}
          new_instances.update(name_to_instance)
        end
      end

      if not new_instances.empty?
        class_variable_set(class_var, register.merge(new_instances))
      end
    end
  end

end

