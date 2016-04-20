## Ruby Finvoice 2.01 XML generator

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
