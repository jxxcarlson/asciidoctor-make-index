



class Hash

  #  hash = Hash.from_string('foo: bar, yuuk: no', :comma, :colon)
  #  hash['foo']
  #  => 'bar'

  #  hash = Hash.from_string("foo: bar\nyuuk: no", :eol, :colon)
  #  hash['foo']
  #  => 'bar'

  def to_s
    elements = []
    self.each do |key, value|
      if self[key]
        elements << "#{key}: #{value}"
      else
        elements << "#{key}: nil"
      end
    end
    elements.join(', ')
  end

  def subhash(keys)
    hash = {}
    self.each do |key, value|
      if keys.include? key
        hash[key] = value
      end
    end
    hash
  end

  def self.from_string(str, key_val_sep, item_sep, option={} )

    item_sep_map = {comma: ',', semicolon: ';'}
    key_val_map = {colon: ':', equals: '='}
    eol_hash = {eol: Constants::EOL}
    item_sep_map = item_sep_map.merge eol_hash

    key_val_sep2 = key_val_map[key_val_sep] || key_val_sep
    item_sep2 =  item_sep_map[item_sep] || item_sep

    items = str.split item_sep2
    result = {}
    items.each do |item|
      kv = item.split key_val_sep2

      if kv.count > 0

        key = kv[0].strip

        if kv.count > 1
          value = kv[1].strip
        else
          value = nil
        end

        if option[:as_symbol]
          key = key.gsub(/^:/, '').gsub('-', '_').to_sym
        end

        result[key] = value
      end

    end

    result
  end

  # Hash.make 'foo=1, bar=2' => {"foo"=>"1", "bar"=>"2"}
  # Hash.make ['foo=1', 'bar=2'] => {"foo"=>"1", "bar"=>"2"}
  def self.make arg
    if arg.class == "".class
      commands = arg.split(', ')
    else
      commands = arg
    end
    hash = {}
    commands.each do  |command|
      key, value = command.split('=')
      hash[key] = value
    end
    hash
  end

end

class Array

  # let foo = ['a', 'b', 'c', 'd', 'e']
  # foo.tail => ["b", "c", "d", "e"]
  # foo.tail 1 => ["b", "c", "d", "e"]
  # foo.tail 2 => ["c", "d", "e"]
  # etc.
  def tail(first_index=1)
    self[first_index..self.count-1]
  end

  # let foo = ['a', 'b', 'c', 'd', 'e']
  # foo.head => ["a"]
  # foo.head 1 => ["a"]
  # foo.head 2 => ["a", "b"]
  # In general, foo = foo.head n + foo.tail n
  def head(last_index=1)
    self[0..last_index-1]
  end

end


class Date

  # today.time_interval_for_days(2)
  # ==>Today...Today + 2
  # today.time_interval_for_days(-7)
  # ==>Today...Today - 7
  def time_interval_for_days(days)
    # return a range from days_before a date to a_date
    raise ArgumentError, "expected 'self' to be a Date" unless self.is_a? Date
    date_now_start = Time.new(self.year, self.month, self.day, 0, 0, 0).utc
    date_now_end = Time.new(self.year, self.month, self.day , 23, 59, 59).utc
    if days >= 0
      date_after_end = date_now_end + days*24*60*60
      puts "date_now_start #{date_now_start}".yellow
      puts "date_after_end #{date_after_end}".yellow
      return (date_now_start...date_after_end)
    else
      date_before_start = date_now_start  + days*24*60*60
      puts "date_now_end #{date_now_end}".yellow
      puts "date_before_start #{date_before_start}".yellow
      return (date_before_start...date_now_end)
    end

  end

end

class String

  # Ensure that string is non-empty and ends with "\n"
  def normalize
    str = self || "\n"
    str = "\n" if str.length == 0
    str += "\n" if str[-1] != "\n"
    str
  end

  def blue
    "\e[1;34m#{self}\e[0m"
  end

  def green
    "\e[1;32m#{self}\e[0m"
  end

  def red
    "\e[1;31m#{self}\e[0m"
  end

  def yellow
    "\e[1;33m#{self}\e[0m"
  end

  def magenta
    "\e[1;35m#{self}\e[0m"
  end

  def cyan
    "\e[1;36m#{self}\e[0m"
  end

  def white
    "\e[1;37m#{self}\e[0m"
  end

  def black
    "\e[1;30m#{self}\e[0m"
  end

  def make_hash(separator = ":")
    pairs = self.split("\n")
    pairs = pairs.select{ |x| x.include? separator}
    puts pairs.to_s.blue
    hash = {}
    pairs.each do |pair|
      pair = pair.gsub(/^#{separator}/, '') if separator == ':'
      a, b = pair.split(separator)
      puts "a: #{a}, b: #{b}".yellow
      a = a.strip
      if b
        b = b.strip
      end
      if b and b != ''
        hash[a] = b
      else
        hash[a] = ''
      end
    end
    hash
  end

  # The new string method
  # 'STUFF #{arg}MORE STUFF',grex 'Foo'
  # generates the regex obtainled by doing
  # the usual interpoalted string substiution
  # which replaces #{arg} by FOO, then
  # calls Regex.new.  If the option 'm'
  # is present, a multilinee regex is returned.
  def grex(key, option='-')
    rx_string = self.gsub('ARG', key)
    if option == 'm'
      Regexp.new rx_string, Regexp::MULTILINE
    else
      Regexp.new rx_string
    end
  end


  def grex2(key, key2, option='-')
    rx_string = self.gsub('ARG2', key2)
    rx_string = rx_string.gsub('ARG', key)
    if option == 'm'
      Regexp.new rx_string, Regexp::MULTILINE
    else
      Regexp.new rx_string
    end
  end

  # 'foo123bar'.alpha_filter => 'foobar'
  # 'foo123bar(' ')'.alpha_filter => 'foobar'
  #
  def alpha_filter(substitution_character = '')
    gsub(/[^a-zA-Z]/, substitution_character)
  end


end


