require 'helpers/import'

import 'helpers/system_checks'
import 'uploader/base'
import 'uploader/service'
import 'uploader/suppressor'

module Uploader
  class S3Service < Service

    def connect!
      # TODO S3 may not work yet.

      if not SystemChecks.gem_available?('aws/s3')
        $stderr.puts %Q{\nThe Amazon S3 service requires the aws-s3 gem (vers >= 0.6.2), which is 
not required by default. Run 'gem install aws-s3' to install it.\n\n}
        raise LoadError
      end

      @bucket_name = @config.bucket
      access_key = ENV[@config.access_key]
      secret_key = ENV[@config.secret_key]

      $stderr.puts "Connecting to AWS..."

      @suppressor.shutup!

      unless AWS::S3::Base.connected?
        options = {
            :access_key_id => access_key,
            :secret_access_key => secret_key,
            :use_ssl => true,
            :port => 443
          }

        if @config.use_proxy
          options.update({
            :proxy => {
              :host => @config.proxy['host'],
              :port => @config.proxy['port']
              }
            })
        end

        AWS::S3::Base.establish_connection!(options)
        @suppressor.ok

      else
        @suppressor.ok
        $stderr.puts "AWS already connected."
      end

      @s3_bucket = AWS::S3::Bucket.find(@bucket_name)
    end

    def close!
      AWS::S3::Base.disconnect!
    end

    def upload(remote_path, contents)
      raise UploadArgumentError if not remote_path.is_a?(Path)

      if contents.is_a?(File)
        contents_to_upload = contents.read

      elsif contents.is_a?(String)
        contents = contents

      else
        raise UnrecognizedContentType

      end

      upload_contents_to_s3(local_path, contents_to_upload)
    end

    def upload_contents_to_s3(remote_path, contents, mime_type=nil)
      $stderr.puts "Attempting to upload #{remote_path} to S3"

      destination = Path.new(@config.remote_root_path) + remote_path

      @suppressor.shutup!

      # Prepare the object.
      object = @s3_bucket.new_object
      object.key = destination
      object.value = contents

      # Store the object first...
      object.store

      #if not mime_type.blank?
      #  #object.content_type = mime_type
      #  #object.store
      #else
      #  ext = File.extname(local_path)
      #  if content_types.keys.include? ext
      #    #object.content_type = content_types[ext]
      #    #object.store
      #  end
      #end

      # ... then set the ACLs.
      public_read_grant = AWS::S3::ACL::Grant.grant(:public_read)
      object.acl.grants << public_read_grant
      object.acl(object.acl)

      @suppressor.ok

      if @s3_bucket.objects.include?(object)
        $stderr.puts "Successfully uploaded #{local_path} to S3!"
      else
        $stderr.puts "Something went wrong uploading #{local_path} to S3."
      end
    rescue => detail
      $stderr.puts "Uploader#upload_contents_to_s3 exception."
      $stderr.puts detail.message
    end

    def self.content_types
      {
        ".png" => "image/png",
        ".jpg" => "image/jpeg",
        ".jpeg" => "image/jpeg",
        ".pdf" => "application/pdf",
        ".jar" => "application/java-archive",
        ".txt" => "text/plain",
        ".html" => "text/html",
        ".css" => "text/css",
        ".js" => "text/javascript"
      }
    end

  end
  Service.register(:s3 => S3Service)
end

