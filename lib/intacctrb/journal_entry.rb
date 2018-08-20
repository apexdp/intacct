module IntacctRB
  class JournalEntry < IntacctRB::Base

    def create
      if object.intacct_id.present?
        return_error('You tried to create an object that already had an intacct_id')
      else
        send_xml('create') do |xml|
          xml.function(controlid: "f1") {
            xml.send("create") {
              xml.glbatch {
                je_xml xml
              }
            }
          }
        end
        return_result(response)
      end
    end

    def update
      unless object.intacct_id.present?
        return_error('You tried to update an object without an intacct_id')
      else
        send_xml('update') do |xml|
          xml.function(controlid: "f1") {
            xml.send("update") {
              xml.glbatch {
                je_xml xml
              }
            }
          }
        end
        return_result(response)
      end
    end

    # def delete
    #   # return false unless object.payment.intacct_system_id.present?
    #   send_xml('delete') do |xml|
    #     xml.function(controlid: "1") {
    #       xml.delete_bill(externalkey: "false", key: object.intacct_key)
    #     }
    #   end
    #
    #   successful?
    # end

    def get_list(options = {})
      send_xml('readByQuery') do |xml|
        xml.function(controlid: "f4") {
          xml.readByQuery {
            xml.object "glbatch"
            xml.pagesize (options[:max_items] || 0)
            xml.query options[:filter]
            if options[:fields]
              xml.fields {
                options[:fields].each do |field|
                  xml.field field.to_s
                end
              }
            end
          }
        }
      end

      if successful?
        @data = []
        @response.xpath('//glbatch').each do |invoice|
          @data << OpenStruct.new({
            id: invoice.at("RECORDNO").content,
            batch_number: invoice.at("BATCHNO").content,
            journal_id: invoice.at("JOURNAL").content,
            date: Date.strptime(invoice.at("BATCH_DATE").content,'%m/%d/%Y'),
            modified_at: DateTime.strptime(invoice.at("MODIFIED").content, '%m/%d/%Y %H:%H:%S'),
            description: invoice.at("description").content,
            state: invoice.at("STATE").content
          })
        end
        @data
      else
        false
      end
    end

    def get(options = {})
      send_xml('read') do |xml|
        xml.function(controlid: "f4") {
          xml.read {
            xml.object "glbatch"
            xml.keys object.try(:intacct_id) || options[:intacct_id]
            if options[:fields]
              xml.fields {
                options[:fields].each do |field|
                  xml.field field.to_s
                end
              }
            end
          }
        }
      end

      if successful?
        @data = []
        @response.xpath('//glbatch').each do |je|
          @data << OpenStruct.new({
            id: je.at("RECORDNO").content,
            batch_number: je.at("BATCHNO").content,
            journal_id: je.at("JOURNAL").content,
            date: Date.strptime(je.at("BATCH_DATE").content,'%Y-%m-%d'),
            modified_at: DateTime.strptime(je.at("WHENMODIFIED").content, '%Y-%m-%dT%H:%M:%S'),
            description: je.at("BATCH_TITLE").content,
            state: je.at("STATE").content,
            rows: get_rows(je)
          })
        end
        if @data.empty?
          false
        else
          @data
        end
      else
        false
      end
    end

    def get_rows(je)
      rows = []
      je.xpath('//glentry').each do |row|
        rows << {
          type: row.at('TR_TYPE').content,
          amount: row.at('AMOUNT').content,
          account_number: (row.at('ACCOUNTNO') ? row.at('ACCOUNTNO').content : nil),
          memo: (row.at('DESCRIPTION') ? row.at('DESCRIPTION').content : nil),
          location_id: (row.at('LOCATION') ? row.at('LOCATION').content : nil),
          department_id: (row.at('DEPARTMENT') ? row.at('DEPARTMENT').content : nil),
          customer_id: (row.at('CUSTOMER') ? row.at('CUSTOMER').content : nil),
          employee_id: (row.at('EMPLOYEE') ? row.at('EMPLOYEE').content : nil),
          project_id: (row.at('PROJECT') ? row.at('PROJECT').content : nil),
          item_id: (row.at('ITEM') ? row.at('ITEM').content : nil)
        }
      end
      rows
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
      object.intacct_key
    end

    def je_xml xml
      xml.recordno object.intacct_id if object.intacct_id
      xml.empower_id if object.empower_id
      xml.empower_class if object.empower_class
      xml.journal object.journal_id
      xml.batch_date date_string(object.date) if object.date
      xml.reverse_date date_string(object.reverse_date) if object.reverse_date
      xml.batch_title object.description
      xml.referenceno object.reference_number
      je_item_fields(xml)
    end

    def je_item_fields xml
      xml.entries {
        object.rows.each do |row|
          xml.glentry {
            xml.tr_type row[:type]
            xml.amount row[:amount]
            xml.accountno row[:account_number]
            xml.description row[:memo]
            xml.location row[:location_id] if row[:location_id]
            xml.department row[:department_id] if row[:department_id]
            xml.customerid row[:customer_id] if row[:customer_id]
            xml.employeeid row[:employee_id] if row[:employee_id]
            xml.projectid row[:project_id] if row[:project_id]
            xml.itemid row[:item_id] if row[:itemid]
            xml.classid row[:class_id] if row[:class_id]
          }
        end
      }
    end

    def date_string(date)
      if date.is_a?(Date) || date.is_a?(DateTime)
        date.strftime('%Y-%m-%d')
      elsif date.is_a? String
        date
      end
    end
  end
end
