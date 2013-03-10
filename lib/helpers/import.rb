require 'pathname'

class FileNotFound < StandardError; end

# An equivalent to 'require_relative' that ensures the require path is absolute to avoid multiple
# imports of the same file.
def import(path)

  # Produce a clean absolute path.
  if not Pathname.new(path).absolute?
    expanded_path = File.expand_path(File.join(File.dirname(__FILE__), "..", path))
  else
    expanded_path = File.expand_path(path)
  end

  # Ensure it ends with ".rb". We're only using "import" for non-Gems.
  rb_path = expanded_path.end_with?(".rb") ? expanded_path : expanded_path + ".rb"

  if File.exists?(rb_path)
    require rb_path
  else
    raise FileNotFound, "#{rb_path} was not found."
  end

rescue => e
  $stderr.puts e.message

end

