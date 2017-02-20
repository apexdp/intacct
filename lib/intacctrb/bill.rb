module IntacctRB
  class Bill < IntacctRB::Base
    attr_accessor :customer_data
    define_hook :custom_bill_fields, :bill_item_fields

    def create
      return false if object.intacct_system_id.present?

      send_xml('create') do |xml|
        xml.function(controlid: "f1") {
          xml.create {
            xml.apbill {
              bill_xml xml
            }
          }
        }
      end

      if !successful?
        raise IntacctRB::Exceptions::Error.new(response.at('//error//description2'))
      end

      object.intacct_id
    end

    def update
      raise 'You must pass an id to update a bill' unless object.intacct_id.present?

      send_xml('update') do |xml|
        xml.function(controlid: "f1") {
          xml.update {
            xml.apbill(key: object.intacct_id) {
              bill_xml xml
            }
          }
        }
      end

      if !successful?
        raise(response.at('//error//description2'))
      end

      object.intacct_id
    end

    def delete
      # return false unless object.intacct_system_id.present?

      send_xml('delete') do |xml|
        xml.function(controlid: "1") {
          xml.delete_bill(externalkey: "false", key: object.intacct_key)
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
      "#{intacct_bill_prefix}#{object.id}"
    end

    def bill_xml xml
      xml.recordno object.intacct_id
      xml.vendorid object.vendor_id
      xml.whenposted object.posted_at
      xml.whencreated object.invoice_date
      xml.whendue object.due_date
      xml.action object.action
      xml.recordid object.record_id
      xml.supdocid object.supdoc_id

      xml.apbillitems {
        object.line_items.each do |line_item|
          xml.apbillitem {
            xml.accountno line_item.account_number
            xml.amount line_item.amount
            xml.entrydescription line_item.memo
            xml.locationid line_item.location_id
            xml.projectid line_item.provider_id
          }
        end
      }

      run_hook :custom_bill_fields, xml
      run_hook :bill_item_fields, xml
    end

    def set_intacct_system_id
      object.intacct_system_id = intacct_object_id
    end

    def delete_intacct_system_id
      object.intacct_system_id = nil
    end

    def delete_intacct_key
      object.intacct_key = nil
    end

    def set_date_time type
      if %w(create update delete).include? type
        if object.respond_to? :"intacct_#{type}d_at"
          object.send("intacct_#{type}d_at=", DateTime.now)
        end
      end
    end
  end
end
