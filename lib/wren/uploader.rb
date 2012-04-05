require 'stringio'
require 'suppressor'
require 'net/ftp'
require 'aws/s3'
require 'fileutils'

class Uploader
  
  attr_accessor :service
  
  def initialize service='ftp', config_dict={}
    @remote_root_path = ""
    @service = service
    @suppressor = Suppressor.new
    @config_dict = config_dict
    
    connect
  end
  
  def connect
    if @service == 'ftp'
      
      @server_name = @config_dict['ftp']['host'].to_s
      @username = @config_dict['ftp']['username'].to_s
      @password = @config_dict['ftp']['password'].to_s
      
      puts "Opening a persistent FTP connection to #{@server_name}"
      
      @ftp = Net::FTP.new
      @ftp.passive = true
      @ftp.connect(@server_name)
      @ftp.login @username, @password
      
      @remote_root_path = @config_dict['ftp']['remote_root_path'].to_s
      
    elsif @service == 's3'
      
      @bucket_name = @config_dict['s3']['bucket'].to_s
      @access_key = ENV[ @config_dict['s3']['access_key'] ].to_s
      @secret_key = ENV[ @config_dict['s3']['secret_key'] ].to_s
      
      puts "Connecting to AWS..."
      
      @suppressor.shutup!
      unless AWS::S3::Base.connected?
        options = {
            :access_key_id => @access_key,
            :secret_access_key => @secret_key,
            :use_ssl => true,
            :port => 443
          }
        
        if @config_dict['proxy']['use_proxy']
          options.update( {
            :proxy => {:host => @config_dict['proxy']['host'], :port => @config_dict['proxy']['port']}
          } )
        end
        
        AWS::S3::Base.establish_connection!( options )
        @suppressor.ok
        
      else
        @suppressor.ok
        puts "AWS already connected."
      end
      
      @s3_bucket = AWS::S3::Bucket.find(@bucket_name)
      @remote_root_path = @config_dict['s3']['remote_root_path'].to_s
      
    elsif @service == 'filesystem' or @service == 'preview' or @service == 'stage'
      
      @remote_root_path = @config_dict[@service]['destination'].to_s
      
    else
      
    end
  end
  
  def set_preview
    puts "Setting preview mode..."
    @service = 'preview'
    @remote_root_path = @config_dict['preview']['destination'].to_s
  end
  
  def prepend_remote_root local_path=""
    path = Pathname.new(local_path).cleanpath.to_s
    return File.join(@remote_root_path, path)
  end
  
  # @param path_to_file String: the LOCAL path to which to upload.
  # @param contents File or String: The stuff to upload.
  def upload local_path="", contents=""
    return if local_path.blank?
    
    if @service == 'ftp'
      if contents.is_a? File
        upload_via_ftp local_path, contents
      elsif contents.is_a? String
        upload_contents_via_ftp local_path, contents
      end
    elsif @service == 's3'
      if contents.is_a? File
        upload_contents_to_s3 local_path, contents.read
      elsif contents.is_a? String
        upload_contents_to_s3 local_path, contents
      end
    elsif @service == 'filesystem' or @service == 'preview' or @service == 'stage'
      if contents.is_a? File
        copy_contents_to_file_system local_path, contents.read, true
      elsif contents.is_a? String
        copy_contents_to_file_system local_path, contents, false
      end
    end
  end
  
  def content_types
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
  
  def copy_contents_to_file_system local_path="", contents="", binary=true
    
    destination = prepend_remote_root local_path
    
    if @service == 'preview'
      puts "Copying #{local_path} to the file system (preview mode) at #{destination}"
    else
      puts "Copying #{local_path} to the file system at #{destination}"
    end
    
    begin
      dest = File.open(destination, "w+")
    rescue => detail
      puts "Error..."
      puts detail.message
      puts "Attempting to create the path."
      
      # Assume the directories leading to the file don't exist. Create them.
      FileUtils::mkdir_p( path_to(destination) )
      dest = File.open(destination, "w+")
    end
    
    unless dest.nil?
      dest.syswrite contents
      dest.close
      puts "Done with #{local_path}."
    end
  end
  
  def upload_contents_to_s3 local_path="", contents="", mime_type=""
    puts "Attempting to upload #{local_path} to S3"
    
    remote_path = prepend_remote_root local_path
    
    @suppressor.shutup!
    
    # Prepare the object.
    object = @s3_bucket.new_object
    object.key = remote_path
    object.value = contents
    
    # Store the object first...
    object.store
    
    if not mime_type.blank?
      #object.content_type = mime_type
      #object.store
    else
      ext = File.extname(local_path)
      if content_types.keys.include? ext
        #object.content_type = content_types[ext]
        #object.store
      end
    end
    
    # ... then set the ACLs.
    public_read_grant = AWS::S3::ACL::Grant.grant(:public_read)
    object.acl.grants << public_read_grant
    object.acl(object.acl)
    
    @suppressor.ok
    
    if @s3_bucket.objects.include?(object)
      puts "Successfully uploaded #{local_path} to S3!"
    else
      puts "Something went wrong uploading #{local_path} to S3."
    end
  rescue => detail
    puts "Uploader#upload_contents_to_s3 exception."
    puts detail.message
  end
  
  # Builds a successive list of paths required to add a directory to FTP.
  # /path/to/file becomes ["/path","/path/to","/path/to/file"]
  def ftp_paths path_to_file=""
    return [] if path_to_file.blank?
    
    dirs = path_to(path_to_file).to_s.split("/")
    current = ""
    paths = []
    dirs.each do |dir|
      if dir != "."
        current += "#{dir}/"
        paths.push current
      end
    end
    return paths
  end

  def path_to file
    if file.is_a?(String)
      if File.directory?(file)
        return file
      else
        return file.to_s.gsub(File.basename(file),"")
      end
    elsif file.is_a?(File)
      if File.directory?(file.path)
        return file.path
      else
        return file.path.gsub(File.basename(file.path),"")
      end
    end
  end
  
  # Just converts the String "contents" into a StringIO object so we can treat it like
  # a file. Then just pass it to the regular upload_via_ftp method.
  def upload_contents_via_ftp local_path="", contents=""
    file = StringIO.new(contents)
    upload_via_ftp local_path, file, false
  end
  
  def upload_via_ftp local_path, file, binary=true
    return if local_path.blank?
    
    remote_path = prepend_remote_root local_path
    
    #if path_to_file.to_s[0].chr == "/"
    #  path_to_file = path_to_file.sub("/","")
    #end
    puts "Opening an FTP connection for #{local_path}"
    
    begin
      if binary
        file.binmode
        @ftp.storbinary("STOR #{remote_path}", file, Net::FTP::DEFAULT_BLOCKSIZE)
      else
        @ftp.storlines("STOR #{remote_path}", file)
      end
    rescue => detail
      puts detail.message
      
      # Assume a no directory error.
      paths = ftp_paths remote_path
      
      # Make all the directories needed.
      paths.each do |path|
        begin
          @ftp.mkdir path
        rescue Net::FTPPermError
          # This directory already exists.
        rescue
          # Ok.
        end
      end
      
      begin
        if binary
          file.binmode
          @ftp.storbinary("STOR #{remote_path}", file, Net::FTP::DEFAULT_BLOCKSIZE)
        else
          @ftp.storlines("STOR #{remote_path}", file)
        end
      rescue => detail
        puts detail.message
      end
    end
  end
  
  def close
    if @service == 'ftp'
      @ftp.close
    elsif @service == 's3'
      AWS::S3::Base.disconnect!
    end
  end
end

