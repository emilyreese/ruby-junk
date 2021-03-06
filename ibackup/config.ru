require "rubygems"
require "bundler/setup"

require "rack_dav"

base_dir = File.dirname(__FILE__)
$LOAD_PATH.unshift base_dir unless $LOAD_PATH.include? base_dir

junk_dir = File.dirname(File.dirname(__FILE__))
$LOAD_PATH.unshift junk_dir unless $LOAD_PATH.include? junk_dir

require "mbdb_parser"
require "MBDBFS"


$TREE ||= begin
  tree = {}

  # make the root entry
  # tree[File::SEPARATOR] = MBDBEntry.new

  MBDBParser.parse(File.join(ENV["BACKUP_PATH"], "Manifest.mbdb")) do |entry|
    # if entry.path && !entry.path.empty?
    #   path = File.join(File::SEPARATOR, entry.domain, entry.path).force_encoding("UTF-8")
    # else
    #   path = File.join(File::SEPARATOR, entry.domain).force_encoding("UTF-8")
    # end
    # path = File.join(File::SEPARATOR, entry.domain, entry.path).force_encoding("UTF-8")
    path = entry.full_path
    
    # raise path if entry.hash == "3a278dfb79753a5e64da864c4ad0e2daa55a2492"

    tree[path] ||= entry

    tree[path].copy(entry) unless tree[path].file_size

    while path != File::SEPARATOR
      up_path = File.join(File.dirname(path), "")

      tree[up_path] ||= begin
        entry = MBDBEntry.new(true)
        entry.full_path = up_path
        entry.permissions = 0o40755
        entry.hash = SillyHasher.hash([path])
        entry.file_size = 0
        entry
      end
      
      # puts "#{tree[up_path]}"
      
      tree[up_path].children ||= []
      tree[up_path].children << tree[path] unless tree[up_path].children.include?(tree[path])
      
      # raise tree[up_path].full_path.class.inspect

      path = up_path
    end
  end

  tree
end

# use Rack::CommonLogger

run RackDAV::Handler.new(:resource_class => MBDBFS, :backup_path => ENV["BACKUP_PATH"], :tree => $TREE)
# run RackDAV::Handler.new(:root => "/tmp")
