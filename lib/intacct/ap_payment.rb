module Intacct
  class APPayment < Intacct::Base
    attr_accessor :customer_data
    define_hook :custom_bill_fields, :bill_item_fields

    def create
      return false if object.intacct_system_id.present?

      send_xml('create') do |xml|
        xml.function(controlid: "f1") {
          xml.send("create_paymentrequest") {
            ap_payment_xml xml
          }
        }
      end
      puts response
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
          xml.get_list(object: "bill", maxitems: "50", showprivate:"true") {
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

      puts response
      if successful?
        @data = []
        @response.xpath('//bill').each do |invoice|
          @data << Invoice.new({
            id: invoice.at("key").content,
            vendor_id: invoice.at("vendorid").content,
            bill_number: invoice.at("billno").content,
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

    def ap_payment_xml xml
      xml.bankaccountid object.bank_account_id
      xml.vendorid object.vendor_id
      xml.paymentmethod object.payment_method
      xml.paymentdate {
        xml.year object.payment_date.strftime("%Y")
        xml.month object.payment_date.strftime("%m")
        xml.day object.payment_date.strftime("%d")
      }
      xml.paymentrequestitems {
        xml.paymentrequestitem {
          xml.key object.bill_key
          xml.paymentamount object.amount
        }
      }
      xml.documentnumber object.check_number
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
