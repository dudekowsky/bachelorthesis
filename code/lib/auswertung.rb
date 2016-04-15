class Hash
  def to_readable
    output = ""
    self.each do |key,val|
      output << "#{key}#{val}"
    end
    output
  end
end
class Array
  def to_readable
    output = ""
    self.each do |entry|
      output << "#{entry}"
    end
    output
  end
end
class Ana
  def initialize(escaped_para_string)
    @escaped_para_string = escaped_para_string
    FileUtils.mkdir_p '../ergebnisse/sortiertewerte'
  end

  def makegraph(x_axis, params_arr, curve_param)
    filedata = sort_values_into_one_file(x_axis, params_arr, curve_param)
    makefiles = make_makefiles(filedata, x_axis, curve_param)
    load_into_gnuplot(makefiles)
  end
  def load_into_gnuplot(makefiles)
    makefiles.each do |makefile|
      %x{gnuplot #{makefile}}
    end
  end
  #curve param means the parameter as in a family of curves
  def sort_values_into_one_file(x_axis, params_arr, curve_params )
    output = []
    grouped_arr = params_arr.group_by{|outerhash| curve_params.map{|curve_param| outerhash[curve_param]}}

    grouped_arr.each do |grouper, x_arr|
      values = ""
      x_arr.each do |sim_para_hash|
        para_string = @escaped_para_string % sim_para_hash
        a = IO.readlines("../ergebnisse/#{para_string}")

        values << "#{sim_para_hash[x_axis]}\t" << a[1]
      end
      constant_parameters = x_arr[0].reject{|key| [x_axis, curve_params].include?(key) }
      filename = "../ergebnisse/sortiertewerte/x#{x_axis}para#{curve_params.to_readable}#{grouper.to_readable}#{constant_parameters.to_readable}"
      output << [grouper, filename,x_arr[0]]
      File.open(filename, "w+") do |file|
        file.write values
      end
    end
    output
  end
  def make_makefiles(filedata, x_axis, curve_param)
    makefiles = []
    [{line: 2, abbr: "P", ylabel: "Bound Probability"},
    {line: 4, abbr: "B", ylabel: "Mean Bound Time"},
    {line: 5, abbr: "U", ylabel: "Mean Unbound Time"}].each do |hash|
      makefiles << make_makefile(filedata, x_axis, curve_param, hash)
    end
    # makefiles << make_makefile_p(filedata, x_axis, curve_param)
    # makefiles << make_makefile_b(filedata, x_axis, curve_param)
    # makefiles << make_makefile_u(filedata, x_axis, curve_param)
    return makefiles
  end
  def make_makefile(filedata, x_axis, curve_param, specify)
    helptext = ""
    constant_parameters = ""
    filedata.each do |tuple|
      curve_param_val = tuple[0]
      filename = tuple[1]
      constant_parameters = tuple[2]
      helptext += "'./#{filename}' u 1:#{specify[:line]} with lines title '#{curve_param} = #{curve_param_val}', "
    end
    helptext[-2] = ""
    text = <<-END
set terminal pngcairo size 1024, 768
set key outside tmargin
set xlabel '#{x_axis}'
set ylabel "#{specify[:ylabel]}"
set output '../bilder/#{specify[:abbr]}gegenx#{x_axis}para.png'
plot #{helptext}
    END
    output_file = "../ergebnisse/sortiertewerte/make#{specify[:abbr]}gegenx#{x_axis}para#{curve_param.to_readable}"
    File.open(output_file,"w+") do |file|
      file.write(text)
    end
    output_file
  end
end
