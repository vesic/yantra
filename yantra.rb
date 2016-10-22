#!/usr/bin/ruby

require "thor"
require "./translate"

class App < Thor
  desc "produce SOURCE DESTIONATION", "translate from source to destination"
  option :input, :aliases => ['-i'], :required => true
  option :output, :aliases => ['-o'], :required => true
  option :to, :aliases => ['-t', '--to'], :required => true
  def produce
    Translate.new.produce options[:input], options[:output], options[:to]
  end
  
  desc "merge FILES DESTIONATION", "combine files"
  option :files, :aliases => ['-f'], :type => :array, :required => true
  option :output, :aliases => ['-o'], :required => true
  def merge
    Translate.new.merge options[:files], options[:output]
  end
end

App.start(ARGV)
