
# Usage:
# Instantiate with a file  ti = TextIndex.new(file: 'infile.adoc')
# or instantiate with a string ti = TextIndex.new(string: 'foo, bar, etc')
# Then execute ti.process('outfile.adoc') to write the indexed version
# of the Asciidoc file to 'outfile.adoc'
class TextIndex

  require_relative 'core_ext'
  require 'ostruct'

  attr_reader :text, :lines, :term_array, :index_map, :index_array, :index

  INDEX_TERM_REGEX = /(\({2}\(*.*?\){2}\)*)/

  # Construct an array of lines
  # by reading a string or a file:
  # foo = TextIndex.new(string: 'ho ho ho')
  # foo = TextIndex.new(file: 'final_word.adoc')
  def initialize(hash)
    @lines = hash[:string].split("\n") if hash[:string]
    @lines = IO.readlines(hash[:file]) if hash[:file]
  end


  # locate the occurrences of terms marked
  # for indexing and return them as an array
  def self.scan_string(str)
    str.scan(INDEX_TERM_REGEX).flatten.map{ |e| e.sub('((','').sub('))','') }
  end

  # Return the terms to be indexwd by
  # scanning the entire @lines array
  def scan
    output = []
    @lines.each do |line|
      term_array = line.scan(INDEX_TERM_REGEX)
      output << term_array
    end
    @term_array = output.flatten.map{ |e| e.sub('((','').sub('))','') }
  end

  def sort_indicator(element)
    components = element[0].split(',')
    if components.count == 1
      components[0].downcase
    else
      components.pop
      components.join(',').strip.downcase
    end
  end

  # Build a hash, the @index_map which maps an index term to an
  # array of positions in the text.  Positions
  # range from 0 to (number of terms) - 1
  # Thus if the text contains the terms
  # 'foo', 'bar', and 'foo' in thar order, then
  #
  #   @index_map = { 'foo': [0, 2], 'bar': [1]}
  #
  # After the @index_map is contructed, it is used
  # to build @index_array -- the corresponding
  # array which is case-insenstive sorted on the
  # index terms.  Thus
  #
  #   @index_array = [ ['bar', [1]], ['foo', [0, 2]] ]
  #
  # @index_map is used in transforming the input
  # text, whereas @index_array is used to construct
  # the index
  #
  def make_index_map
    dict = {}
    @term_array.each_with_index do |element, index|
      if dict[element]
        dict[element] = dict[element] << index
      else
        dict[element] = [index]
      end
    end
    @index_map = dict
    # @index_array = @index_map.to_a.sort{ |a,b| sort_indicator(a) <=> sort_indicator(b) }
    @index_array = @index_map.to_a
    @index_array = @index_array.map{ |el| [el[0].gsub(/[^\w, ]/,''), el[1]]} # reduce
    @index_array = @index_array.sort{ |a,b| sort_indicator(a) <=> sort_indicator(b) }
    @index_array = @index_array.map{ |e| [e[0].split(/, */), e[1]]}
    puts @index_array
  end

  # Map in index term to an inline_macro
  # representing its location in the index.
  # @index_map is used for this.  In the
  # example, the first time "transformed_term"
  # is applied to 'foo' the result is
  #
  #     "index_term::[foo, 0]".
  #
  # The second
  # time it is
  #
  #     "index_term::[foo, 2]"
  #
  # Asciidoctor converter, using the
  # HTML backend for the Asciidoctor-LaTeX
  # extension, transforms these to
  #
  #      "<span class='index_term' id='index_term_0'>foo</a>"
  #
  # etc.  These elements will be the targets of links
  # constructed in the index.
  def transformed_term(term)
    value = @index_map[term].dup
    if  value
      k = value.shift
      @index_map[term] = value
      regex = /\((.*?)\)/
      matches = term.match regex
      css = 'mark'
      if matches
        term = matches[1]
        css = 'invisible'
      end
      value =  "index_term::['#{term}', #{k}, #{css}]"
      puts "INDEX TERM A: #{value}"
      value
    end
  end


  # Apply transform_term to each index term in the given line
  def transform_line(line)
    terms = TextIndex.scan_string(line)
    if terms
      terms.each do |term|
        puts "transform_line, term = #{term}".red
        puts "line = #{line}".cyan
        line = line.gsub("((#{term}))", transformed_term(term))
      end
    end
    line
  end

  # replace the array of lines by an array in which
  # each term ((foo)) has been replaced by an element
  # of the form
  #
  #      index_term::[foo, k]
  #
  # where k is the position of foo in the text
  def transform_lines(outfile)
    file = File.open(outfile, 'w')
    @lines.each do |line|
      file.puts transform_line(line)
    end
    file.close
  end


  # Map each pair like ['bar', [1]] or
  # ['foo', [0,2]] to the corresponding
  # asciidoc reference for the index.
  # In the case at hand these are
  #
  #    <<index_term_1, bar>>
  #
  # and
  #
  #    <<index_term_0, foo>>, <<index_term_2, 2>>
  #
  # In the case of index terms that appear n > 1
  # times, the elements beyond the first are labeled
  # 2, 3, ..., n.  We should loook for a better
  # solution in the pageless environment of the web.
  #
  def reference(reference_elements)
    if reference_elements.count == 1
      # case 'foo', return 'foo'
      ref = reference_elements.pop
    else
      # case 'foo, bar, foo bar', return 'foo, bar'
      # case 'foo, - , foo bar', retur 'foo'
      reference_elements.pop
      last_element = reference_elements.pop.strip
      puts "last_element = #{last_element}".red
      if last_element == '-'
        puts "INSIDE: reference = #{last_element}".cyan
        ref = reference_elements.pop
      else
        reference_elements.push last_element
        ref = "'#{reference_elements.join(', ').strip}'"
      end
    end
    return ref.gsub("'", '')  #Fixme: this is sloppy!
  end

  def index_pair_to_index_item(pair)
    ref = reference(pair[0])
    indices = pair[1].dup
    index = indices.shift

    n = indices.count - 1
    count = 2
    out = ["<<index_term_#{index}, #{ref}>>"]
    if indices
      indices.each do |index|
        out <<  "<<index_term_#{index}, #{count}>>"
        count += 1
      end
    end
    out.join(', ') + " +\n"
  end

  def shift_pair(pair)
    pair[0].shift
  end

  def index_pair_to_index_item3(pair, level)
    reference_list, index_list = pair
    length = reference_list.count
    puts "head #{reference_list[0].to_s}, level = #{level}, length = #{length}".red
    if length == 1
      value= "* <<index_term_#{index_list.shift}, #{reference_list.shift}>>\n"
    else
      head = reference_list.shift
      asterisks = '*'*(level)
      value = "* #{head}\n#{asterisks}#{index_pair_to_index_item3([reference_list, index_list], level + 1)}"
    end
    return value
  end


  # Insert letter "A", "B", etc in index
  # before first letter of index term changes
  def heading(reference_list)
    first_char = reference_list[0][0].downcase
    puts "first_char = #{first_char}".magenta
    if first_char =~ /\w/ && first_char != @previous_char
      @previous_char = first_char
      "\n\n*#{first_char.upcase}* +\n"
    else
      ""
    end
  end

  # Insert letter "A", "B", etc in index
  # before first letter of index term changes
  def heading2(reference_list)
    first_char = reference_list[0][0].downcase
    if first_char =~ /\w/ && first_char != @previous_char
      @previous_char = first_char
      "\n\n.*#{first_char.upcase}*\n"
    else
      ""
    end
  end


  # Construct the Asciidoc version of the index
  # by applying 'index_pair_to_index_item' to
  # each element and accumulating the result
  # in the string 'output'
  def make_index
    output = ''
    @previous_char = nil
    @index_array.each do |index_pair|
      reference_list = index_pair[0]
      output << heading(reference_list)
      output << index_pair_to_index_item(index_pair)
    end
    @index = output
  end

  # Construct the Asciidoc version of the index
  # by applying 'index_pair_to_index_item' to
  # each element and accumulating the result
  # in the string 'output'
  def make_index2
    output = ''
    @previous_char = nil
    @index_array.each do |index_pair|
      reference_list = index_pair[0]
      output << heading2(reference_list)
      puts index_pair.to_s.yellow
      @running_head = index_pair[0][0]
      output << index_pair_to_index_item3(index_pair, 1)
    end
    puts output.yellow
    @index = output
  end


  # Put it all together: write the transformed
  # Asciidoc file to outfile, along with the index.
  # The output is now ready to be processed by Asciidoctor.
  def preprocess(outfile)
    scan
    make_index_map
    make_index
    transform_lines(outfile)

    file = File.open(outfile, 'a')
    file.puts "\n\n:!numbered:\n\n== Index\n\n"
    file.puts index
    file.close
  end

end
