module IntacctRB
  class Vendor < IntacctRB::Base
    def create
      send_xml('create') do |xml|
        xml.function(controlid: "f1") {
          xml.create {
            xml.vendor {
              vendor_xml xml
            }
          }
        }
      end

      if !successful?
        raise IntacctRB::Exceptions::Vendor.new(response.at('//error//description2'))
      end

      new_vendor = response.xpath('//result//data//vendor').first
      new_vendor.at('VENDORID').content
    end

    def update updated_vendor = false
      @object = updated_vendor if updated_vendor
      return false if object.intacct_system_id.nil?


      send_xml('update') do |xml|
        xml.function(controlid: "1") {
          xml.update_vendor(vendorid: intacct_system_id) {
            vendor_xml xml
          }
        }
      end

      successful?
    end

    def delete
      return false if object.intacct_system_id.nil?

      @response = send_xml('delete') do |xml|
        xml.function(controlid: "1") {
          xml.delete_vendor(vendorid: intacct_system_id)
        }
      end

      successful?
    end

    def get_list(options = {})
      send_xml('get_list') do |xml|
        xml.function(controlid: "f4") {
          xml.get_list(object: "vendor", maxitems: (options[:max_items] || 0),
            start: (options[:start] || 0), showprivate:"true") {
            filter_xml(xml, options)
            if options[:fields]
              xml.fields {
                fields.each do |field|
                  xml.field field.to_s
                end
              }
            end
          }
        }
      end

      if successful?
        @data = []
        @response.xpath('//vendor').each do |vendor|
          @data << OpenStruct.new({
            id: vendor.at("vendorid").content,
            name: vendor.at("name").content,
            tax_id: vendor.at("taxid").content,
            total_due: vendor.at("totaldue").content,
            billing_type: vendor.at("billingtype").content,
            vendor_account_number: vendor.at("vendoraccountno").content
          })
        end
        @data
      else
        false
      end
    end

    def intacct_object_id
      "#{intacct_vendor_prefix}#{object.id}"
    end

    def vendor_xml xml
      xml.name "#{object.company_name.present? ? object.company_name : object.full_name}"
      xml.vendtype object.vendor_type if object.vendor_type.present?
      xml.taxid object.tax_id
      xml.billingtype "balanceforward"
      xml.status "active"
      xml.vendoraccountno object.vendor_account_number
      xml.paymethodkey object.payment_method
      xml.onetime object.one_time || false
      xml.displaycontact {
        xml.contactname object.company_name
        xml.printas object.company_name
        xml.companyname object.company_name
        xml.firstname object.first_name
        xml.lastname object.last_name
        xml.phone1 object.business_phone
        xml.cellphone object.cell_phone
        xml.email1 object.email
        if object.billing_address.present?
          xml.mailaddress {
            xml.address1 object.billing_address.address1
            xml.address2 object.billing_address.address2
            xml.city object.billing_address.city
            xml.state object.billing_address.state
            xml.zip object.billing_address.zipcode
          }
        end
      }
      if object.ach_routing_number.present?
        xml.achenabled "#{object.ach_routing_number.present? ? "true" : "false"}"
        xml.achbankroutingnumber object.ach_routing_number
        xml.achaccountnumber object.ach_account_number
        xml.achaccounttype "#{object.ach_account_type.capitalize+" Account"}"
        xml.achremittancetype "#{(object.ach_account_classification=="business" ? "CCD" : "PPD")}"
      end
    end
  end
end
