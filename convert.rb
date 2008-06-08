module Convert
  extend self
  
  def start(start_file)
    Thread.new do
      system(%Q{/Library/Application\\ Support/Techspansion/vh131ffmpeg -y -i #{start_file} -threads 4 -s 800x480 -aspect 800/480 -r 23.98 -vcodec h264 -g 200 -qmin 8 -b 230k -bf 1 -level 41 -loop 1 -sc_threshold 40 -partp4x4 1 -rc_eq "blurCplx^(1-qComp)" -refs 3 -qmax 51 -async 50 -acodec libfaac -ar 48000 -ac 2 -ab 128k #{start_file}.mp4 2>> #{file}; echo done >> #{done_file}})
    end
    
    while(!File.exists?(file))
      sleep(0.2)
    end
  end
  
  def file
    @file ||= "/tmp/progress-#{self.object_id}"
  end
  
  def done_file
    @done_file ||= "/tmp/finished-#{self.object_id}"
  end
  
  def done?
    File.exists?(done_file) && open(done_file).read =~ /done/
  end

  def cleanup
    File.unlink(done_file) if File.exists?(done_file)
    File.unlink(file) if File.exists?(file)
  end
  
  def contents
    @contents ||= open(file).read
  end
  
  def frames
  	@frames ||= begin
  		frame_rate = contents[/0.0,,,,,Video,.*q=.*,([\d\.]+)$/,1].to_f
  		duration = contents[/Duration-(\d+)/,1].to_f
  		(frame_rate * duration).to_i
  	end
  end

  def current_frame
    return 0 unless File.exists?(file)
    
    matches = open(file).read.scan(/frame=\s*(\d+)/)
    (matches.last && matches.last[0]).to_i || 0
  end
end
