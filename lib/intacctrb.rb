require "intacctrb/version"
require 'net/http'
require 'nokogiri'
require 'hooks'
require 'ostruct'
require "intacctrb/logger"
require "intacctrb/base"
require "intacctrb/contact"
require "intacctrb/customer"
require "intacctrb/employee"
require "intacctrb/journal_entry"
require "intacctrb/vendor"
require "intacctrb/invoice"
require "intacctrb/bill"
require "intacctrb/ap_payment"
require "intacctrb/account"
require "intacctrb/attachment"

require "intacctrb/exceptions/base"
require "intacctrb/exceptions/vendor"
require "intacctrb/exceptions/bill"
require "intacctrb/exceptions/attachment"
require "intacctrb/exceptions/ap_payment"

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def present?
    !blank?
  end
end

module IntacctRB
  extend self

  attr_accessor :xml_sender_id  , :xml_password    ,
                :app_user_id    , :app_company_id  , :app_password ,
                :invoice_prefix , :bill_prefix     ,
                :vendor_prefix  , :customer_prefix

  def setup
    yield self
  end
end
