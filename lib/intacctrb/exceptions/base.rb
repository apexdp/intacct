module IntacctRB
  module Exceptions
    class Base < StandardError
      def initialize(message)
        super(message)
      end
    end
  end
end
