## Ruby Finvoice 2.01 XML generator

[![Code Climate](https://codeclimate.com/repos/57833ba7a9cc75009200817e/badges/5530dabe015ddffb8ac6/gpa.svg)](https://codeclimate.com/repos/57833ba7a9cc75009200817e/feed)
[![Test Coverage](https://codeclimate.com/repos/57833ba7a9cc75009200817e/badges/5530dabe015ddffb8ac6/coverage.svg)](https://codeclimate.com/repos/57833ba7a9cc75009200817e/coverage)
[![Build Status](https://semaphoreci.com/api/v1/devlab/finvoice/branches/master/badge.svg)](https://semaphoreci.com/devlab/finvoice)

One way conversion from Ruby hash to Finvoice 2.01 XML file

### Usage

```ruby
# Invoice hash
invoice = {
    invoice: {
        number: "1234",
        date: "2016-02-25"
    },
    seller: {...},
    buyer: {...},
    rows: [...]
}

document = Finvoice201.build_from_hash(invoice)
document.valid? # => true or false
document.errors # => array of errors from XML schema validation
xml = document.to_xml # => xml contents
Finvoice201.validate(xml) # returns errors from XML schema validation
```
