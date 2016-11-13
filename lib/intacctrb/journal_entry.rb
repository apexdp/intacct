module IntacctRB
  class JournalEntry < IntacctRB::Base

    def create
      return false if object.intacct_system_id.present?
      send_xml('create') do |xml|
        xml.function(controlid: "f1") {
          xml.send("create_gltransaction") {
            je_xml xml
          }
        }
      end

      successful?
    end

    def delete
      # return false unless object.payment.intacct_system_id.present?
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
          xml.get_list(object: "gltransaction", maxitems: (options[:max_items] || 0),
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
            batch_number: invoice.at("batchno").content,
            journal_id: invoice.at("journalid").content,
            date_created: get_date_at('datecreated', invoice),
            date_modified: get_date_at('datemodified', invoice),
            description: invoice.at("description").content,
            state: invoice.at("state").content
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

    def je_xml xml
      xml.journalid object.journal_id
      if object.date
        xml.datecreated {
          xml.year object.date.strftime("%Y")
          xml.month object.date.strftime("%m")
          xml.day object.date.strftime("%d")
        }
      end
      if object.reverse_date
        xml.reversedate {
          xml.year object.reverse_date.strftime("%Y")
          xml.month object.reverse_date.strftime("%m")
          xml.day object.reverse_date.strftime("%d")
        }
      end
      xml.description object.description
      xml.referenceno object.reference_number
      je_item_fields(xml)
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

    def je_item_fields xml
      puts "object:: #{object}"
      xml.gltransactionentries {
        object.rows.each do |row|
          xml.glentry {
            xml.trtype row[:type]
            xml.amount row[:amount]
            xml.glaccountno row[:account_number]
            if row[:date]
              xml.datecreated {
                xml.year row[:date].strftime("%Y")
                xml.month row[:date].strftime("%m")
                xml.day row[:date].strftime("%d")
              }
            end
            xml.memo row[:memo]
            xml.locationid row[:location_id] if row[:location_id]
            xml.departmentid row[:department_id] if row[:department_id]
            xml.customerid row[:customer_id] if row[:customer_id]
            xml.employeeid row[:employee_id] if row[:employee_id]
            xml.projectid row[:project_id] if row[:project_id]
            xml.itemid row[:item_id] if row[:itemid]
            xml.classid row[:class_id] if row[:class_id]
          }
        end
      }
    end

    def to_date_xml xml, field_name, date
      xml.send(field_name) {
        xml.year date.strftime("%Y")
        xml.month date.strftime("%m")
        xml.day date.strftime("%d")
      }
    end
  end
end
