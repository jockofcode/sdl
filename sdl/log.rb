module SDL
  module Log
    @enabled = false
    @path    = ""

    def self.open(path = "/tmp/sdl.log")
      @path    = path
      @enabled = true
      File.write(@path, "")
      write("=== sdl session started ===")
    end

    def self.write(msg)
      return unless @enabled
      File.open(@path, "a") { |f| f.puts(msg) }
    end

    def self.close
      write("=== sdl session ended ===")
      @enabled = false
    end
  end
end
