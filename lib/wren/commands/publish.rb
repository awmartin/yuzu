
module Wren::Command
  
  # Publish is the primary mechanism to upload files to a remote server such as via FTP or S3.
  class Publish < PublicationCommand

    def self.help method
      case method
      when :default
        "Updates files on the remote server."
      when :all
        "Updates all files on remote server. A fresh start."
      when :changed
      when :resources
      when :images
      when :assets
      else
      end
    end
  end
end
