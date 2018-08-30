module IntacctRB
  class APPayment < IntacctRB::Base
    attr_accessor :customer_data
    define_hook :custom_bill_fields, :bill_item_fields

    def create
      return false if object.intacct_system_id.present?

      send_xml('create') do |xml|
        xml.function(controlid: "f1") {
          xml.send("create_appayment") {
            ap_payment_xml xml
          }
        }
      end

      if !successful?
        raise IntacctRB::Exceptions::APPayment.new(response.at('//error//description2'))
      end

      object.intacct_id
    end

    def update
      raise 'You must pass an id to update an ap payment' unless object.intacct_id.present?

      send_xml('update') do |xml|
        xml.function(controlid: "f1") {
          xml.update {
            xml.appayment(key: object.intacct_id) {
              ap_payment_xml xml
            }
          }
        }
      end

      if !successful?
        raise(response.at('//error//description2'))
      end

      object.intacct_id
    end

    def reverse
      return false unless object.id.present?

      send_xml('delete') do |xml|
        xml.function(controlid: "1") {
          xml.reverse_appayment(key: object.id) do |xml|
              xml.datereversed do |xml|
                xml.year object.date.year
                xml.month object.date.month
                xml.day object.date.day
              end
          end
        }
      end

      successful?
    end

    def get_list(options = {})
      send_xml('get_list') do |xml|
        xml.function(controlid: "f4") {
          xml.get_list(object: "appayment", maxitems: (options[:max_items] || 0),
            start: (options[:start] || 0), showprivate:"true") {
            if options[:filters]
              xml.filter {
                xml.logical(logical_operator: "and") do
                  options[:filters][:and_filters].each do |filter|
                    xml.expression do
                      filter.each_pair do |k,v|
                        xml.send(k,v)
                      end
                    end
                  end
                  if options[:filters][:or_filters]
                    xml.logical(logical_operator: "or") do
                      options[:filters][:or_filters].each do |filter|
                        xml.expression do
                          filter.each_pair do |k,v|
                            xml.send(k,v)
                          end
                        end
                      end
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
        @response.xpath('//appayment').each do |payment|
          item = OpenStruct.new({
            id: payment.at("key").content,
            vendor_id: payment.at("vendorid").content,
            payment_amount: payment.at("paymentamount").content,
            payment_trx_amount: payment.at("paymenttrxamount").content,
            payment_method: payment.at("paymentmethod").content,
            payment_account_id: payment.at("financialentity").content,
            state: payment.at("transactionstate").content,
            date: get_date_at('paymentdate', payment),
            date_cleared: get_date_at('cleareddate', payment),
            cleared: payment.at("cleared").content,
          })
          payment.xpath('.//appaymentitem').each do |payment_item|
            item[:payment_items] ||= []
            item[:payment_items] << {
              bill_id: payment_item.at('billkey').content,
              line_item_id: payment_item.at('lineitemkey').content,
              gl_account_number: payment_item.at('glaccountno').content,
              amount: payment_item.at('amount').content,
              department_id: payment_item.at('departmentid').content,
              location_id: payment_item.at('locationid').content,
              trx_amount: payment_item.at('trx_amount').content,
              currency: payment_item.at('currency').content
            }
          end
          @data << item
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
      xml.key object.intacct_id unless object.intacct_id.blank?
      xml.bankaccountid object.bank_account_id unless object.bank_account_id.blank?
      xml.chargecardid object.charge_card_id unless object.charge_card_id.blank?
      xml.vendorid object.vendor_id
      xml.memo object.memo
      xml.paymentmethod object.payment_method
      xml.checkdate {
        xml.year Date.parse(object.payment_date).year
        xml.month Date.parse(object.payment_date).month
        xml.day Date.parse(object.payment_date).day
      }
      xml.checkno object.check_number
      xml.billno object.bill_number
      xml.payitems {
        object.line_items.each do |line_item|
          xml.payitem {
            xml.glaccountno line_item.account_number
            xml.paymentamount line_item.amount
            xml.locationid line_item.location_id
          }
        end
      }
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
