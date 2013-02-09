# Haml and AWS put out a lot of junk. Redirect stdout and stderr to /dev/null to suppress these
# useless warnings, then restore stdout and stderr at the end.
class Suppressor
  def initialize
    @hole = File.new('/dev/null', 'w')
    @orig_stdout = $stdout
    @orig_stderr = $stderr
  end
  
  # Redirect stdout to /dev/null
  def shutup!
    $stdout = @hole
    $stderr = @hole
  end
  
  # Restore stdout and stderr
  def ok
    $stdout = @orig_stdout
    $stderr = @orig_stderr
  end
  
  def close!
    @hole.close
  end
end
