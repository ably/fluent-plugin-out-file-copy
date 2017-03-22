module Fluent
  class FileCopyOutput < BufferedOutput
    Fluent::Plugin.register_output('file_copy', self)

    attr_reader :directory, :filename, :time_format

    desc "The directory path of the output files"
    config_param :directory, :string

    desc "The name for the output file which supports interpolation of tags with ${tag} and the following strftime date values %Y %m %d %H %M"
    config_param :filename, :string

    desc "Time format used for log output"
    config_param :time_format, :string, default: "%y-%m-%dT%H:%M:%S.%LZ"

    TAG_MATCH_REGEX = /\${([\w-]+)}/
    DATE_MATCH_REGEX = /%[YmdHM]/

    FILE_PERMISSION = 0644
    DIR_PERMISSION = 0755

    def start
      super
    end

    def shutdown
    end

    def configure(conf)
      super

      @dir_perm = system_config.dir_permission || DIR_PERMISSION
      @file_perm = system_config.file_permission || FILE_PERMISSION
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def path_for_record(record)
      filename.gsub(TAG_MATCH_REGEX) do |tag|
        if record.has_key?(tag)
          tag[record]
        else
          "#{tag}-MISSING"
        end
      end
    end

    def write(chunk)
      output = Hash.new([])

      chunk.msgpack_each do |(tag, time, record)|
        output[path_for_record(record)] << [time.utc.strftime(time_format), record.to_s].join(' ')
      end

      output.each do |path, data|
        dir = File.join(directory, path)
        FileUtils.mkdir_p dir unless File.folder?(dir)
        File.open(path, 'a') {|f| f.write(data.join('\n')) }
      end
    end
  end
end
