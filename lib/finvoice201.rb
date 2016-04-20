require 'nokogiri'
require 'finvoice201/document'

# lib/finvoice.rb
module Finvoice201

  VERSION     = "2.01"
  XSD_SCHEMA  = "Finvoice2.01.xsd"

  # Build a Finvoice::Document object
  def self.build_from_hash(hash)
    Finvoice201::Document.new(hash)
  end

  # Validate Finvoice XML file according to Finvoice 2.01 schema
  def self.validate(xml)
    xsd = Nokogiri::XML::Schema(File.read(File.join( File.dirname(__FILE__), XSD_SCHEMA)))
    doc = Nokogiri::XML(xml)
    xsd.validate(doc).map do |error|
      error.message
    end
  end

end
