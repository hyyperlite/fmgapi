# Nick Petersen (2014) - All Rights Reserved
#
# Ah2hh.convert - converts an array-of-hashes to a hash-of-hashes.  Top level hash keys will be created based on the value of
# they key corresponding to the provided attribute "index" in the array's hashes.
# Takes 2 and only two parameters.  The first parameter should be a reference to an array object containing hashes.  This
# must be an object of class Array.  The second argument should be the index (value of hash key from array) to sort
# and create top level hash keys with.  This must be an object of class String or Symbol.  The references within the
# Array Hashes must be known to be of type String or Symbol in advance.

module Ah2hh

  def Ah2hh.convert(array, index)
    begin

      if ! array.is_a?(Array)
        raise ArgumentError.new('The object passed for array parameter is not an object type of Array')
      end

      if index.is_a?(Symbol) != true && index.is_a?(String) != true
        raise ArgumentError.new('Index provided must be of type String or Symbol')
      end

      hohs = Hash.new

      array.each {|x|
        if ! x.has_key?(index)
          raise ArgumentError.new('Index provided doesn\'t exist in one or more of the hashes in the array')
        end
        if hohs.has_key?(x[index])
          raise 'Values of index provided are not unique'
        end
        hohs[x[index]] = Hash.new
        x.each { |key, val|
          unless key == index
            hohs[x[index]][key] = val
          end
        }
      }
      return hohs

    rescue Exception => e
      puts
      puts 'Error: ' + e.message
      puts e.backtrace.inspect
      puts ''
      return e
    end
  end
end