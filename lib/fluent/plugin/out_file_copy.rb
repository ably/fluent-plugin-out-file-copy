module Fluent
  class FileCopyOutput < BufferedOutput
    Fluent::Plugin.register_output('file_copy', self)

    attr_reader :directory, :filename, :time_format
    attr_reader :dir_perm, :file_perm

    desc "The directory path of the output files"
    config_param :directory, :string

    desc "The name for the output file which supports interpolation of tags with ${tag} and the following strftime date values %Y %m %d %H %M"
    config_param :filename, :string

    desc "Time format used for log output"
    config_param :time_format, :string, default: "%Y-%m-%dT%H:%M:%S.%3N%z"

    TAG_MATCH_REGEX = /\${([\w-]+)}/
    DATE_MATCH_REGEX = /%([YymdHM])/

    FILE_PERMISSION = 0644
    DIR_PERMISSION = 0755

    FIELD_ORDERING = {
      "environment" => 5,
      "region" => 10,
      "instance_id" => 15,
      "instance_roles" => 20,
      "container_name" => 30,
      "source" => 25,
      "severity" => 30,
      "message" => 1000
    }

    USE_FIELDS = {
      "environment" => "env",
      "region" => "reg",
      "instance_id" => "i",
      "instance_roles" => "role",
      "source" => "src",
      "container_name" => "cont",
      "message" => "msg",
      "hostname" => "h",
      "thread" => "thread",
      "severity" => "s"
    }

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
      [tag, Time.at(time.to_r).to_f, record].to_msgpack
    end

    def path_for_record(record)
      filename.gsub(TAG_MATCH_REGEX) do
        tag = Regexp.last_match[1]
        if record.has_key?(tag)
          record[tag]
        else
          "#{tag}.MISSING"
        end
      end.gsub(DATE_MATCH_REGEX) do
        Time.now.utc.strftime("%#{Regexp.last_match[1]}")
      end
    end

    def format_record(time, record)
      time_formatted = begin
        Time.at(time).to_datetime.strftime(time_format)
      rescue StandardError => e
        'unknown'
      end

      sorted_fields = record.sort_by do |key, val|
        [FIELD_ORDERING.fetch(key, 999), key]
      end.map do |key, val|
        if %w(@timestamp time).include?(key)
          begin
            time_formatted = Time.parse(val).strftime(time_format)
          rescue StandardError => e
            # Do nothing
          end
        elsif USE_FIELDS.has_key?(key)
          "#{USE_FIELDS.fetch(key)}=#{val.to_s.strip}"
        end
      end.compact

      if sorted_fields.empty?
        "t=#{time_formatted} #{record}"
      else
        (["t=#{time_formatted}"] + sorted_fields).join(' ')
      end
    end

    def write(chunk)
      output = Hash.new {[]}

      chunk.msgpack_each do |(tag, time, record)|
        output[path_for_record(record)] += [format_record(time, record)]
      end

      output.each do |path, data|
        out_path = File.join(directory, path)
        out_dir = File.dirname(out_path)
        FileUtils.mkdir_p(out_dir, mode: dir_perm) unless File.directory?(out_dir)
        File.open(out_path, 'a', file_perm) {|f| f.write(data.join("\n")) }
      end
    end
  end
end
