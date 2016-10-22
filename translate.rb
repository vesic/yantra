require "http"
require "json"
require 'colorize'
require 'yaml'

class Translate
  def initialize
  end
  
  def produce(input_file, output_file, to_lang)
    apiKey = YAML.load_file("config.yml")["apiKey"]
    source_text = [];
    translated_text = []

    File.open(input_file).each do |row|
      source_text << row.strip
    end
    
    # split array into chunks 
    source_text.each_slice(100) do |chunk|
      # text = chunk.inject { |memo, word| memo << "&text=" << word }
      # from each chunk build a 100 '&text=<word-to-translate>' pairs
      text_params = ""
      chunk.each { |el| text_params << "&text=" << el }
      # start measuring req
      startTime = Time.now
      response = HTTP.get("https://translate.yandex.net/api/v1.5/tr.json/translate?key=#{apiKey}#{text_params}&lang=#{to_lang}")
      response = JSON.parse(response);
      status_code = response["code"];
      # check for error code
      if status_code.equal? 200
        # extract translated words
        translated_response = response["text"]
        translated_response.each do |word|
          # of there is more than one word split
          inner = word.split(/\s*[ ,;:]\s*/)
          # concatenate new array to translated words
          translated_text.concat(inner);
        end
          # end measuring req
          endTime = Time.now
          # diag msg
          # puts "Translated #{chunk.length.to_s.colorize(:red)} words in #{(endTime - startTime).round(2).to_s.colorize(:green)} seconds"
      else
        # if status code is something other than 200
        # print msg and abort
        abort("Fail: #{response}")
      end
    end
    
    # if all's well print output file
    File.open(output_file, 'w') do |file|
      words_written = 0 # counter
      # sort and remove duplicates
      translated_text.uniq.sort.each do |word|
        # don't write if there is non-alpha chars contained in the word
        if word.index(/[^[:alnum:]]/).nil?
          file.puts word 
        else 
          # puts "#non-alpha: #{word}"
        end
        # diag msg
        puts "Line:#{words_written += 1} #{word.colorize(:yellow)}"
      end
    end
    
    puts "Completed original:#{translated_text.length} final:#{translated_text.uniq.length}"    
  end
  
  def merge_files files, output_file
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
        # puts "Line:#{counter += 1} #{word.colorize(:yellow)}"
      end
    end
  end
end
