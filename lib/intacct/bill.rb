module Intacct
  class Bill < Intacct::Base
    attr_accessor :customer_data
    define_hook :custom_bill_fields, :bill_item_fields

    def create
      return false if object.payment.intacct_system_id.present?

      # Need to create the customer if one doesn't exist
      unless object.customer.intacct_system_id
        intacct_customer = Intacct::Customer.new object.customer
        unless intacct_customer.create
          raise 'Could not grab Intacct customer data'
        end
      end

      # Create vendor if we have one and not in Intacct
      if object.vendor and object.vendor.intacct_system_id.blank?
        intacct_vendor = Intacct::Vendor.new object.vendor
        if intacct_vendor.create
          object.vendor = intacct_vendor.object
        else
          raise 'Could not create vendor'
        end
      end

      send_xml('create') do |xml|
        xml.function(controlid: "f1") {
          xml.send("create_bill") {
            bill_xml xml
          }
        }
      end

      successful?
    end

    def delete
      return false unless object.payment.intacct_system_id.present?

      send_xml('delete') do |xml|
        xml.function(controlid: "1") {
          xml.delete_bill(externalkey: "false", key: object.payment.intacct_key)
        }
      end

      successful?
    end

    def get_list(options = {})
      send_xml('get_list') do |xml|
        xml.function(controlid: "f4") {
          xml.get_list(object: "bill", maxitems: (options[:max_items] || 0),
            start: (options[:start] || 0), showprivate:"true") {
            if options[:filters]
              xml.filter {
                options[:filters].each do |filter|
                  xml.expression do
                    filter.each_pair do |k,v|
                      xml.send(k,v)
                    end
                  end
                end
              }
            end
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
        @response.xpath('//bill').each do |invoice|
          @data << OpenStruct.new({
            id: invoice.at("key").content,
            vendor_id: invoice.at("vendorid").content,
            bill_number: invoice.at("billno").content,
            po_number: invoice.at("ponumber").content,
            state: invoice.at("state").content,
            date_posted: get_date_at('dateposted', invoice),
            date_due: get_date_at('datedue', invoice),
            date_paid: get_date_at('datepaid', invoice),
            total: invoice.at("totalamount").content,
            total_paid: invoice.at("totalpaid").content,
            total_due: invoice.at("totaldue").content,
            termname: invoice.at("termname").content,
            description: invoice.at("description").content,
            modified_at: invoice.at("whenmodified").content
          })
        end
        @data
      else
        false
      end
    end

    def get_date_at(xpath, object)
      year = object.at("#{xpath}/year").content
      month = object.at("#{xpath}/month").content
      day = object.at("#{xpath}/day").content
      if [year,month,day].any?(&:empty?)
        nil
      else
        Date.new(year.to_i,month.to_i,day.to_i)
      end
    end

    def intacct_object_id
      "#{intacct_bill_prefix}#{object.payment.id}"
    end

    def bill_xml xml
      xml.vendorid object.vendor.intacct_system_id
      xml.datecreated {
        xml.year object.payment.created_at.strftime("%Y")
        xml.month object.payment.created_at.strftime("%m")
        xml.day object.payment.created_at.strftime("%d")
      }
      xml.dateposted {
        xml.year object.payment.created_at.strftime("%Y")
        xml.month object.payment.created_at.strftime("%m")
        xml.day object.payment.created_at.strftime("%d")
      }
      xml.datedue {
        xml.year object.payment.paid_at.strftime("%Y")
        xml.month object.payment.paid_at.strftime("%m")
        xml.day object.payment.paid_at.strftime("%d")
      }
      run_hook :custom_bill_fields, xml
      run_hook :bill_item_fields, xml
    end

    def set_intacct_system_id
      object.payment.intacct_system_id = intacct_object_id
    end

    def delete_intacct_system_id
      object.payment.intacct_system_id = nil
    end

    def delete_intacct_key
      object.payment.intacct_key = nil
    end

    def set_date_time type
      if %w(create update delete).include? type
        if object.payment.respond_to? :"intacct_#{type}d_at"
          object.payment.send("intacct_#{type}d_at=", DateTime.now)
        end
      end
    end
  end
end
