require 'json'

TITLES = JSON.load(File.open('../titles.id.txt'))

Pattern = Struct.new(:category, :regexp) do
  def match(string)
    string =~ regexp
  end
end

KEYWORDS = File.read('keywords.regexp').split(/\n/).map { |kw| Regexp.new(kw) }

class Clasifier
  def initialize
    @patterns = File.read('patterns.txt') .split(/\n/).map do |pattern|
      pattern.sub!(/ #.*$/, '')
      category, regexp = pattern.reverse.split(',', 2).map(&:reverse)
      regexp = regexp[/\/(.*)\//, 1] if regexp
      category = category[/'(.*)'/, 1] if category
      regexp ?  Pattern.new(category, Regexp.new("\\b#{regexp}\\b", 'i')) : nil
    end.compact
  end

  def run(string)
    @patterns.find_all { |pattern| pattern.match(string) }
  end

  def size
    @patterns.size
  end

  def features_vec(string)
    keywords = KEYWORDS.map { |pattern| pattern.match(string) ? 1 : 0 }
    regexp_vec = @patterns.map { |pattern| pattern.match(string) ? 1 : 0 }
    sizes_vec = [
      [1, Math.log(string.size,10)/10].min,
      [1, Math.log(string.split(/\s*/).size,10)/10].min,
      [1, Math.log(string.split(/\n\s*\n/).size,10)/10].min
    ]
    keywords + regexp_vec + sizes_vec
  end
end

@c = Clasifier.new

def get_categories(id, title, text)
  puts "=" * 80
  res = @c.run(text)
  puts "####{id}:#{res.map(&:category).uniq.join(',')}"
  puts
  p res
  puts
  puts text
end

Dir['../backup/*/[0-9]*.txt'].sort_by { |f| f[/(\d+)\.txt/, 1] }.each do |file|
  id = file[/(\d+)\.txt/, 1]
  title = TITLES[id]
  fail "ID=#{id.inspect}: do not have title for file: #{file}" unless title
  body = File.read(file)
  content = [title, body].join("\n")
  categories = get_categories(id, title, content)
  #puts @c.features_vec(content).unshift(id).join(',')
end
