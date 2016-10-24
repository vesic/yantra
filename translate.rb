require "http"
require "json"
require "colorize"
require "yaml"

class Translate
  def initialize
  end
  
  def produce(input_file, output_file, to_lang)
    apiKey = YAML.load_file("config.yml")["apiKey"]
    source_text = []
    translated_text = []
    totalCount = 0
    totalStartTime = Time.now
    
    File.open(input_file).each do |row|
      source_text << row.strip
    end
    
    # split array in chunks 
    source_text.each_slice(100) do |chunk|
      # text = chunk.inject { |memo, word| memo << "&text=" << word }
      
      totalCount += chunk.length
      # from each chunk build a 100 '&text=<word-to-translate>' pairs
      text_params = ""
      chunk.each { |el| text_params << "&text=" << el }
      # start measuring req time
      startTime = Time.now
      response = HTTP.get("https://translate.yandex.net/api/v1.5/tr.json/translate?key=#{apiKey}#{text_params}&lang=#{to_lang}")
      response = JSON.parse(response)
      status_code = response["code"]
      # check status code
      if status_code.equal? 200
        # extract translated words
        translated_response = response["text"]
        translated_response.each do |word|
          # of there is more than one word split
          inner = word.split(/\s*[ ,;:]\s*/)
          # concatenate new array to translated words
          translated_text.concat(inner);
        end
          # end measuring req time
          endTime = Time.now
          # diag msg
          puts "Translated #{totalCount.to_s.colorize(:green)} words in #{format_seconds(endTime - totalStartTime)}"
      else
        # if status code is something other than 200
        # print msg and abort
        abort("Fail: #{response}")
      end
    end
    
    # diag msg in case we want to see dups
    # p translated_text.count, translated_text.sort

    # if all's well print output file
    File.open(output_file, 'w') do |file|
      words_written = 0 # counter
      # sort and remove duplicates
      translated_text.uniq.sort.each do |word|
        # TODO: check correctness for words like E-mail, ympyrä-aluevaltaus and such
        # don't write if there is non-alpha chars contained in the word
        if word.index(/[^[:alnum:]]/).nil?
          file.puts word 
          puts "Line: #{words_written += 1} #{word.colorize(:green)}"
        else
          puts "#non-alpha: #{word}"
        end
      end
    end
    
    puts "Done. Input count: #{translated_text.length.to_s.colorize(:green)}. Output (including invalids) count: #{translated_text.uniq.length.to_s.colorize(:green)}"    
  end
  
  def merge files, output_file
    # combine text from files array
    all = []

    # open all files and read text in
    files.each do |file|
      File.open(file).each do |line|
        all << line.strip
      end
    end
    
    File.open(output_file, 'w') do |file|
      counter = 0
      # once again sort and remove duplicates
      all.uniq.sort.each do |word|
        file.puts word
        puts "Line: #{(counter += 1).to_s.colorize(:green)} #{word.colorize(:green)}"
      end
    end
    
    puts "File #{output_file} written"
  end

  def format_seconds total_seconds
    minutes = (total_seconds / 60) % 60
    seconds = total_seconds % 60

    "%02d:%02d".colorize(:green) % [minutes.to_i, seconds.to_i]
  end
end
