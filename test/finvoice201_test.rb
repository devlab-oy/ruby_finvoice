require 'minitest/autorun'
require 'finvoice201'
require 'json'

class Finvoice201Test < Minitest::Test

  def setup
    @finvoice_xml = File.read('test/files/Finvoice201_wo_SOAP_example_27022014.xml')
    @invoice_hash = JSON.parse(File.read('test/files/invoice.json'), symbolize_names: true)
  end

  def test_should_initialize
    assert_equal Finvoice201::Document, Finvoice201::Document.new(@invoice_hash).class
  end

  def test_validate_generated_finvoice201_xml
    finvoice = Finvoice201.build_from_hash(@invoice_hash)
    assert finvoice.valid?
    assert_equal [], finvoice.errors
  end

  def test_validate_example_finvoice
    assert_equal [], Finvoice201.validate(@finvoice_xml) # no errors
  end

end
