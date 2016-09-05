# lib/finvoice/document.rb
module Finvoice201
  class Document
    def initialize(invoice)
      @invoice = invoice
      @content = nil
    end

    def to_xml
      @content ||= add_finvoice
      @content.to_xml
    end

    def valid?
      Finvoice201.validate(self.to_xml).empty?
    end

    def errors
      Finvoice201.validate(self.to_xml)
    end

    ### Finvoice mappings ###

    def add_finvoice
      @content = Nokogiri::XML::Builder.new(encoding: "ISO-8859-15") do |root|
        attributes = {
          "Version" => VERSION,
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
          "xsi:noNamespaceSchemaLocation" => XSD_SCHEMA
        }
        root.Finvoice(attributes) do |finvoice|
          add_message_transmission_details  finvoice
          add_seller_party_details          finvoice
          add_seller_information_details    finvoice
          add_buyer_party_details           finvoice
          add_invoice_details               finvoice
          add_payment_status_details        finvoice
          add_invoice_row                   finvoice
          add_epi_details                   finvoice
          add_invoice_url_name_text         finvoice
          add_invoice_url_text              finvoice
        end
      end

      stylesheet = Nokogiri::XML::ProcessingInstruction.new(@content.doc, "xml-stylesheet", 'type="text/xsl" href="Finvoice.xsl"')
      @content.doc.root.add_previous_sibling(stylesheet)
      @content
    end

    def add_from_identifier(context)
      context.FromIdentifier @invoice.dig(:from_identifier)
    end

    def add_from_intermediator(context)
      context.FromIntermediator @invoice.dig(:from_intermediator)
    end

    def add_message_sender_details(context)
      context.MessageSenderDetails do |message_sender_details|
        add_from_identifier     message_sender_details
        add_from_intermediator  message_sender_details
      end
    end

    def add_message_transmission_details(parent)
      parent.MessageTransmissionDetails do |context|
        add_message_sender_details context

        context.MessageReceiverDetails do |message_receiver_details|
          message_receiver_details.ToIdentifier @invoice.dig(:to_identifier)
          message_receiver_details.ToIntermediator @invoice.dig(:to_intermediator)
        end

        context.MessageDetails do |message_details|
          message_details.MessageIdentifier "123"
          message_details.MessageTimeStamp  Time.now.strftime("%FT%R")
        end
      end
    end

    def add_seller_party_details(finvoice)
      finvoice.SellerPartyDetails do |seller_party_details|
        seller_party_details.SellerPartyIdentifier        @invoice.dig :seller, :bid
        seller_party_details.SellerPartyIdentifierUrlText ""
        Array(@invoice.dig(:seller, :name)).each { |name| seller_party_details.SellerOrganisationName name }
        #seller_party_details.SellerOrganisationDepartment ""
        seller_party_details.SellerOrganisationTaxCode    @invoice.dig :seller, :vat_number
        seller_party_details.SellerPostalAddressDetails do |seller_postal_address_details|
          seller_postal_address_details.SellerStreetName             @invoice.dig :seller, :address
          seller_postal_address_details.SellerTownName               @invoice.dig :seller, :city
          seller_postal_address_details.SellerPostCodeIdentifier     @invoice.dig :seller, :zipcode
          seller_postal_address_details.CountryCode                  @invoice.dig :seller, :country_code
          seller_postal_address_details.CountryName                  @invoice.dig :seller, :country
        end
      end
    end

    def add_seller_account_details(context)
      context.SellerAccountDetails do |seller_account_details|
        seller_account_details.SellerAccountID @invoice.dig(:seller, :iban), "IdentificationSchemeName" => "IBAN"
        seller_account_details.SellerBic       @invoice.dig(:seller, :bic),  "IdentificationSchemeName" => "BIC"
      end
    end

    def add_seller_information_details(finvoice)
      finvoice.SellerInformationDetails do |seller_information_details|
        add_seller_account_details seller_information_details
      end
    end

    def add_buyer_party_details(finvoice)
      finvoice.BuyerPartyDetails do |buyer_party_details|
        buyer_party_details.BuyerPartyIdentifier        @invoice.dig :buyer, :bid
        buyer_party_details.BuyerOrganisationName       @invoice.dig :buyer, :name
        #buyer_party_details.BuyerOrganisationDepartment ""
        buyer_party_details.BuyerOrganisationTaxCode    @invoice.dig :buyer, :vat_number
        buyer_party_details.BuyerPostalAddressDetails do |buyer_postal_address_details|
          buyer_postal_address_details.BuyerStreetName              @invoice.dig :buyer, :address
          buyer_postal_address_details.BuyerTownName                @invoice.dig :buyer, :city
          buyer_postal_address_details.BuyerPostCodeIdentifier      @invoice.dig :buyer, :zipcode
          buyer_postal_address_details.CountryCode                  @invoice.dig :buyer, :country_code
          buyer_postal_address_details.CountryName                  @invoice.dig :buyer, :country
          buyer_postal_address_details.BuyerPostOfficeBoxIdentifier
        end
      end
    end

    def add_vat_specification_details(invoice_details)
      tax_rates = @invoice.dig(:rows).map { |row| row[:tax] }.uniq

      tax_rates.each do |tax_rate|
        vat_base_amount = @invoice.dig(:rows).select {|row| row[:tax] == tax_rate}.inject(0) {|sum, row| sum += row[:total_amount].to_f}
        vat_rate_amount = @invoice.dig(:rows).select {|row| row[:tax] == tax_rate}.inject(0) {|sum, row| sum += row[:total_tax_amount].to_f}

        invoice_details.VatSpecificationDetails do |vat_specification_details|
          vat_specification_details.VatBaseAmount amount(vat_base_amount), currency_identifier
          vat_specification_details.VatRatePercent amount(tax_rate)
          vat_specification_details.VatRateAmount amount(vat_rate_amount), currency_identifier
        end
      end
    end

    def add_payment_overdue_fine_details(payment_terms_details)
      #payment_terms_details.PaymentOverDueFineDetails do |payment_over_due_fine_details|
      #  payment_over_due_fine_details.PaymentOverDueFineFreeText "Viivästyskorko"
      #  payment_over_due_fine_details.PaymentOverDueFinePercent "7,5"
      #end
    end

    def add_payment_terms_details(invoice_details)
      invoice_details.PaymentTermsDetails do |payment_terms_details|
        payment_terms_details.PaymentTermsFreeText  @invoice.dig(:invoice, :terms)
        payment_terms_details.InvoiceDueDate        date(@invoice.dig :invoice, :due_date), "Format" => "CCYYMMDD"
        add_payment_overdue_fine_details            payment_terms_details
      end
    end

    def add_invoice_details(finvoice)
      finvoice.InvoiceDetails do |invoice_details|
        invoice_details.InvoiceTypeCode               "INV01"
        invoice_details.InvoiceTypeText               "Invoice"
        invoice_details.OriginCode                    "Original"
        invoice_details.InvoiceNumber                 @invoice.dig(:invoice, :number)
        invoice_details.InvoiceDate                   date(@invoice.dig :invoice, :date), "Format" => "CCYYMMDD"
        #invoice_details.OrderIdentifier               ""
        invoice_details.InvoiceTotalVatExcludedAmount amount(@invoice.dig :invoice, :total_amount), currency_identifier
        invoice_details.InvoiceTotalVatAmount         amount(@invoice.dig :invoice, :total_tax_amount), currency_identifier
        invoice_details.InvoiceTotalVatIncludedAmount amount(@invoice.dig :invoice, :total_amount_with_tax), currency_identifier

        add_vat_specification_details                 invoice_details
        invoice_details.InvoiceFreeText               @invoice.dig(:invoice, :comment)
        add_payment_terms_details                     invoice_details
      end
    end

    def add_payment_status_details(context)
      context.PaymentStatusDetails do |payment_status_details|
        payment_status_details.PaymentStatusCode "NOTPAID"
      end
    end

    def add_invoice_row(context)
      @invoice.dig(:rows).each_with_index do |row, index|
        context.InvoiceRow do |invoice_row|
          invoice_row.ArticleIdentifier     row.dig(:sku)
          invoice_row.ArticleName           row.dig(:description)
          invoice_row.DeliveredQuantity     row.dig(:quantity), "QuantityUnitCode" => "kpl"
          # invoice_row.OrderedQuantity       row.dig(:quantity) # if differs from DeliveredQuantity
          invoice_row.InvoicedQuantity      row.dig(:total_amount_with_tax), "QuantityUnitCode" => "EUR"
          invoice_row.UnitPriceAmount       amount(row.dig(:price)), currency_identifier
          invoice_row.RowPositionIdentifier index + 1
          invoice_row.RowFreeText           row.dig(:comment)
          invoice_row.RowVatRatePercent     amount(row.dig(:tax))
          invoice_row.RowVatAmount          amount(row.dig :total_tax_amount), currency_identifier
          invoice_row.RowVatExcludedAmount  amount(row.dig :total_amount), currency_identifier
        end
      end
    end

    def add_epi_details(context)
      context.EpiDetails do |epi_details|
        epi_details.EpiIdentificationDetails do |epi_identification_details|
          epi_identification_details.EpiDate       date(@invoice.dig :invoice, :date), "Format" => "CCYYMMDD"
          epi_identification_details.EpiReference  "0"
        end
        epi_details.EpiPartyDetails do |epi_party_details|
          epi_party_details.EpiBfiPartyDetails do |epi_bfi_party_details|
            epi_bfi_party_details.EpiBfiIdentifier @invoice.dig(:seller, :bic), "IdentificationSchemeName" => "BIC"
          end
          epi_party_details.EpiBeneficiaryPartyDetails do |epi_beneficiary_party_details|
            epi_beneficiary_party_details.EpiNameAddressDetails Array(@invoice.dig(:seller, :name)).first
            epi_beneficiary_party_details.EpiBei                @invoice.dig(:seller, :bid)
            epi_beneficiary_party_details.EpiAccountID          @invoice.dig(:seller, :iban), "IdentificationSchemeName" => "IBAN"
          end
        end
        epi_details.EpiPaymentInstructionDetails do |epi_payment_instruction_details|
          epi_payment_instruction_details.EpiPaymentInstructionId     ""
          epi_payment_instruction_details.EpiRemittanceInfoIdentifier @invoice.dig(:invoice, :reference_number), "IdentificationSchemeName" => "ISO"
          epi_payment_instruction_details.EpiInstructedAmount         amount(@invoice.dig :invoice, :total_amount_with_tax), currency_identifier
          epi_payment_instruction_details.EpiCharge("ChargeOption" => "SLEV")
          epi_payment_instruction_details.EpiDateOptionDate           date(@invoice.dig :invoice, :due_date), "Format" => "CCYYMMDD"
        end
      end
    end

    def add_invoice_url_name_text(context)
      # 0..n
      context.InvoiceUrlNameText @invoice.dig(:invoice, :invoice_url_name) unless @invoice.dig(:invoice, :invoice_url_name).nil?
    end

    def add_invoice_url_text(context)
      # 0..n
      context.InvoiceUrlText @invoice.dig(:invoice, :invoice_url_text) unless @invoice.dig(:invoice, :invoice_url_text).nil?
    end

    def add_stylesheet(finvoice)
      pi = Nokogiri::XML::ProcessingInstruction.new(finvoice.doc, "xml-stylesheet", 'href="Finvoice.xsl" type="text/xsl"')
      finvoice.doc.root.add_previous_sibling pi
    end

    private

      def currency_identifier
        {"AmountCurrencyIdentifier" => "EUR"}
      end

      def date(date)
        Date.parse(date).strftime('%Y%m%d')
      end

      def amount(value)
        sprintf("%.2f", value.to_f.round(2)).to_s.gsub('.', ',')
      end
  end
end
