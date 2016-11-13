# IntacctRB

This is a WIP fork of the Intacct API client at https://github.com/cj/intacct.
Goal is to create a full-featured API wrapper for Intacct.

## Status
Alpha; forked and added the features I needed *right now*. Plan to spend some time
refactoring and testing, but not sure when that will be.

## Installation

Add this line to your application's Gemfile:

    gem 'intacct'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install intacct

## Usage

get_list
Example
to filter for vendorid = 'V100'
client.get_list(filters: [{field: 'vendorid', operator: '=', value: "V100"}])

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
