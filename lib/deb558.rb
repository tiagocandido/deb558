require 'deb558/version'
require 'date'
require 'deb558/config'
require 'deb558/parser'

module Deb558
  def self.read_file filename
    parser.parse_file filename
  end

  def self.parser
    Deb558::Parser.new
  end
end