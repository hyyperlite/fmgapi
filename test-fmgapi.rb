require_relative 'fmgapi'
require_relative '../ah2hh/ah2hh'
require 'trollop'
require 'base64'
require 'nori'
require "nokogiri"

#######################################
###### Options Handling ###############
#######################################
opts = Trollop::options {
  version 'v0.1 (c) Nick Petersen'
  banner <<-EOS
FortiManager XML API Access

Usage:
    fmgmain [options] <filenames>+
where [options] are:
  EOS

  opt :wsdl_file, 'Location of FMG API WSDL File', :default => './fmg506.wsdl', :type => String
  opt :fmg_api_url, 'URL & port for FMG', :default => 'https://10.0.2.16:8080', :type => String
  opt :namespace, 'FMG Namespace', :default => 'http://r200806.ws.fmg.fortinet.com/', :type => String
  opt :login, 'FMG API Login ID', :default => 'admin', :type => String
  opt :passwd, 'FMG API Password', :default => '', :type => String
  opt :file, 'Configuration File', :type => String
}

#puts "Executing with the following options:"
#opts.each { |x| puts "#{x}"}

#####################################
##### Execution #####################
#####################################
fmgapi = FmgApi.new(opts[:wsdl_file], opts[:fmg_api_url], opts[:namespace], opts[:login], opts[:passwd])
fazapi = FmgApi.new(opts[:wsdl_file], 'https://10.0.1.15:8080', opts[:namespace], opts[:login], opts[:passwd])
fmg100c = FmgApi.new(opts[:wsdl_file], 'https://10.0.1.14:8080', opts[:namespace], opts[:login], '')
fmglab1 = FmgApi.new(opts[:wsdl_file], 'https://1.1.1.3:8080', opts[:namespace], 'admin', '')

################################################################################################################

#myresult = fmgapi.get_adom_list
# mydevices = Array.new
# mydevices[0] = {:serial_number => 'FGVM020000018110', :vdom_name => 'D2'}
# mydevices[1] = {:dev_id => '234', :vdom_id => '2298'}
# mydevices[2] = {:dev_id => '234', :vdom_id => '3178'}
#myresult = fmgapi.add_adom({:name => 'addAdomTest'}, mydevices)
#myresult = fmgapi.add_adom({:name => 'addAdomTest'})
#myresult = fmgapi.add_adom({:name => 'apitest1', :serial_number => 'FGVM020000018111', :vdom_name => 'root'}) ## test adding vdom with adom using device sn
#myresult = fmgapi.add_adom({:name => 'apitest1', :dev_id => '234', :vdom_name => 'root'}) ## test adding vdom with adom using device id
#myresult = fmgapi.add_adom({:name => 'apitest1', :serial_number => 'FGVM020000018111', :vdom_id => '3', :mr => '1'}) ## :test for mr specified without :version
#myresult = fmgapi.add_adom({:name => 'apitest1', :vdom_id => '3'})  #test for error when not all VDOM args specified

#myresult = fmg100c.add_device({:ip => '10.0.1.1', :password => 'c0ns3qu3nc3', :name => 'FWF60D'})
#myresult = fmgapi.add_group({:name => 'apigroup1'})  #simple add group by just name
#myresult = fmgapi.add_group({:name => 'apigroup4', :group_name => 'apigroup5'})  ## add with group_name (existing group membership test)
#myresult = fmgapi.add_group({:name => 'apigroup3', :device_sn => 'FGVM020000018111'})  #simple add group by just name

#myinstalltargets = Array.new
#myinstalltargets[0] = {:dev => {:name => 'MSSP-1', :vdom => {:name => 'root'}}}
#myinstalltargets[1] = {:dev => {:name => 'MSSP-1', :vdom => {:name => 'transparent'}}}
#myresult = fmgapi.add_policy_package({:policy_package_name => 'default'}, myinstalltargets)
#myresult = fmgapi.add_policy_package({:policy_package_name => 'newPackage'}, myinstalltargets)

#mytargetpkgs = Array.new
#mytargetpkgs[0] = {:name => 'root', :pkg => {:oid => '602'}}
#mytargetpkgs[1] = {:name => 'root', :pkg => {:oid => '603'}}
#myresult = fmgapi.assign_global_policy({:policy_package_name => 'Test'}, mytargetpkgs)
#myresult = fmgapi.assign_global_policy({:policy_package_name => 'Test'}, {:name => 'root', :pkg => {:oid => '602'}})

#myresult = fmgapi.create_script({:adom => 'root', :name=>'apitest1', :content => "get sys status\nconfig global\nget gui console status \n"})
#myresult = fmgapi.delete_adom(:adom_name => 'quarantine')
#myresult = fmgapi.delete_adom(:adom_oid => '301')
#myresult = fmgapi.delete_config_rev({:dev_id => '234', :rev_id => '4'})
#myresult = fmg100c.delete_device(:serial_number => 'FWF60D4613000043')

#myresult = fmg100c.delete_group({:adom => 'root', :grp_name => 'testgroup'})
#myresult = fmgapi.delete_script(:name => '12345')

#mydevices = Array.new
#mydevices[0] = {:serial_number => 'FGVM020000018110', :vdom_name => 'D2'}
#mydevices[1] = {:dev_id => '234', :vdom_id => '2298'}
#mydevices[2] = {:dev_id => '234', :vdom_id => '3178'}
#mymeta = Array.new
#mymeta[0] = {:name => 'meta1', :value => 'value1'}
#mymeta[1] = {:name => 'meta2', :value => 'value2'}
#myresult = fmgapi.edit_adom({:name => 'apitest1'}, mydevices)
#myresult = fmgapi.edit_adom({:name => 'apitest1'}, false, mymeta)
#myresult = fmgapi.edit_adom({:name => 'customerA', :version => '500', :mr => '2'})
#myresult = fmgapi.edit_group_membership(:adom => 'root', :grp_name => 'editGroupTest', :add_group_name_list => 'subGroupTest1, subGroupTest2' )
#myresult = fmgapi.get_adom_by_name(:adom => 'customerA')
#myresult = fmgapi.get_adom_by_oid(:adom_id => '152')
#myresult = fmgapi.get_adom_list
#myresult = fmgapi.get_config({:revision_number => '4', :dev_id => '234'})
#myresult = fmgapi.get_config_revision_history({:dev_id => '234'})
#myresult = fmgapi.get_device(:serial_number => 'FGVM020000018110')
#myresult = fmgapi.get_device_license_list
#myresult = fmgapi.get_device_list
#myresult = fazapi.get_device_list
#myresult = fmgapi.get_device_vdom_list(:dev_id => '234')
#myresult = fazapi.get_faz_archive({:adom => 'root', :dev_id => 'FWF60D4613000043', :file_name => '1712625325:0', :type => '6'})
#myresult = fazapi.get_faz_archive({:dev_id => 'FWF60D4613000043', :file_name => '1712625325:0', :type => '6'})
#myresult = fazapi.get_faz_config
myresult = fmgapi.get_fmg_config
#myresult = fazapi.get_faz_generated_report   ### Doesn't work yet, issues with finding report name
#myresult = fmg100c.get_group_list(:adom => 'root')
#myresult = fmgapi.get_group({:groupid => '101', :name => 'All_FortiGate', :adom=>'customerA'})
#myresult = fmgapi.get_instlog({:serial_number => 'FGVM020000018110'})
#myresult = fmgapi.get_package_list(:adom => 'root')
#myresult = fmgapi.get_script(:script_name => 'cli-sys-status')
#myresult = fmgapi.get_script_log({:script_name => 'cli-sys-status', :sn => 'FGVM020000018110'})
#myresult = fmgapi.get_script_log_summary({:sn => 'FGVM020000018110', :max_logs => '200'})
#myresult = fmgapi.get_system_status()
#myresult = fmgapi.get_task_detail('186', 'customerA')
#myresult = fmgapi.import_policy({:adom_name => 'root', :dev_name => 'MSSP-1', :vdom_name => 'root'})
#myresult = fmgapi.install_config({:adom => 'root', :pkgoid => '572'})
#myresult = fazapi.list_faz_generated_reports({:start_date => '20140401', :end_date => '20140101'})
#myresult = fazapi.list_faz_generated_reports({:start_date => '20140401', :end_date => '20140101'})
#myresult = fmgapi.list_revision_id({:dev_id => '234', :rev_name => 'API Install'})
#myresult = fazapi.remove_faz_archive({:adom => 'root', :dev_id => 'FWF60D4613000043', :file_name => '1712625326:0', :type => '6'})
#myresult = fmgapi.retrieve_config({:dev_id => '234', :rev_name => 'API-Retrieve'})
#myresult = fmgapi.revert_config({:rev_id => '4', :dev_id => '234'})
#myresult = fazapi.run_faz_report({:report_template => 'Admin and System Events Report'})
#myresult = fmgapi.run_script({:name => 'apitest1', :serial_number => 'FGVM020000018110'})
#myresult = fazapi.search_faz_log(:device_name => 'FWF60D', :search_criteria => 'vd=root srcip=192.168.1.12 or srcip=192.168.19.2')
#myresult = fazapi.set_faz_config(:config => "config system dns \n set secondary 166.102.165.11 \n end \n")

puts myresult.class
puts myresult

####################################################################################################################
####################################################################################################################
## Misc Snippets below for future reference etc
###################################################################################################################
#puts '### DATE TIME STUFF ###'
#testtime = DateTime.parse('04042014 01:10:30').strftime("%Y-%m-%dT%H:%M:%S").to_s rescue false
#puts testtime
#puts DateTime.strptime('2014-04-25T00:00:00', '%Y--%m--%d')

#### The following can be used to format config files that lost formatting due to SAVON processing
#### may still  need some additional work but this fixes most of the issues.
#myresult = myresult.gsub(/\s{2,}/,"\n")
#myresult = myresult.gsub(/([0-9a-zA-Z])(end)/, "\\1 \n\\2\n")
#myresult = myresult.gsub(/(end)([0-9a-zA-Z])/, "\\1 \n\\2\n")
#myresult = myresult.gsub(/([0-9])(config)/, "\\1\n\\2")
####
#myfile = File.open('c:\Users\nick\Desktop\apiconfig.conf', "w+")
#myfile.write(myresult)
#myfile.close



#### the following can be used to write an archive file to a file
#myfile = File.open('c:\Users\nick\Desktop\archive.pcap', "w+")
#myfile.write(Base64.decode64(myresult[:data]))
#myfile.close

#if myresult.is_a?(Hash)
#  puts 'Success:'
#  puts myresult
#  puts myresult.keys
#elsif myresult.is_a?(Array)
#  puts myresult
#  puts 'converting array to hash of hashes.....'
#  converted = Ah2hh.convert(myresult, :oid)
#
#  if converted.is_a?(Hash)
#    puts converted.class
#    puts converted.keys
#    puts converted
#  else
#    puts 'Error: converted result was not a Hash. This indicates that an exception occurred and was handled'
#  end
#else
#  puts 'FMG Query did not return a hash or array this is likely due to an error. Check error log.'
#end



