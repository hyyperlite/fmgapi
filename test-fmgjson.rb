require_relative 'fmgjson'
require 'json'

fmgapi = FmgJson.new('10.10.10.10', 'admin', '', 0)


##  Add address object FMG
# data = {:params => [:url => 'pm/config/adom/root/obj/firewall/address',
#                     :data =>
#                         [:name => "new_addr1",
#                         :type => 0,
#                         :'associated-interface' => 'any',
#                         :subnet =>
#                           ['10.1.1.1',
#                           '255.255.255.0'
#                           ]
#                         ]
#                     ],
#                     :method => 'add'}

## Get address objects FMG
#data = {:params => [:url => 'pm/config/adom/root/obj/firewall/address'],
#        :method => 'get'}

## Request (save working)
jsonreq = {:params => [:url => '/sys/status']}
method = 'get'

## Request  FW Address Group
#jsonreq = {:params => [:url => 'pm/config/adom/root/obj/firewall/addrgrp']}
#method = 'get'

## Request  Add FW group
# jsonreq = {:params => [:url => 'pm/config/adom/root/obj/firewall/addrgrp',
#                         :data => [:name => 'jsontest1',
#                                   :type => '0',
#                                   :associated-interface => 'any',
#                                   :subnet => ['10.100.100.1', '255.255.255.255']
#                                 ]
#                       ]
#           }
# method = 'add'

result = fmgapi.exec(jsonreq, method)

#puts '#### Result ####'
#puts result
#puts result.class
puts '#### Result As JSON ####'
puts JSON.pretty_generate(result)