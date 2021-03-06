module Asset
  class Item

    attr_accessor :path, :type, :key, :modified, :app, :name, :kpath

    # Init
    def initialize(*args)
      @path, @type, @key, @modified = args
      @app = !!(@path =~ /^bundle\.(js|css)$/)
      @name = @path.rpartition('.')[0]
      @kpath = "#{@name}-#{kext}"
    end

    # Get the files for this item
    def files(bundle = true)
      (@app and bundle) ? ::Asset.bundle[@type] : [@path]
    end

    # Get the sources for this item
    def sources
      files(!p?)
    end

    # Get the full path
    def src
      File.join('/assets', @type, (p? ? @kpath : @path))
    end

    # Get the content, will be compressed in production typically.
    def content(compress = p?)
      compress ? cached : joined
    end

    # The cached content
    def cached
      @cached ||= (read_cache || write_cache)
    end

    # Read cache
    def read_cache
      File.read(cache_path) rescue nil
    end

    # Store in cache
    def write_cache
      compressed.tap{|c| File.atomic_write(cache_path){|f| f.write(c)}}
    end

    # Cache path
    def cache_path
      @cache_path ||= File.join(::Asset.cache, kext)
    end

    # Key and extension
    def kext
      @kext ||= %{#{@key}.#{@type}}
    end

    # Compressed joined files
    def compressed
      @compressed ||= case @type
      when 'css'
        Sass::Engine.new(joined, :syntax => :scss, :cache => false, :style => :compressed).render rescue joined
      when 'js'
        Uglifier.compile(joined, :mangle => false, :comments => :none) rescue joined
      end
    end

    # All files joined
    def joined
      @joined ||= files.map{|f| File.read(File.join(::Asset.path, @type, f))}.join
    end

    # Print data
    def print
      [:path, :type, :key, :name, :modified, :files, :content].map{|r| "#{r.upcase}: #{send(r).inspect}"}.join("\n")
    end

    private

    # Production mode?
    def p?
      ::Asset::Util.p?
    end
  end
end
