require_relative 'fmgapi'
require_relative 'ah2hh'
require 'trollop'
require 'base64'

#######################################
###### Options Handling ###############
#######################################
opts = Trollop::options {
  version 'v0.1 (c) Nick Petersen'
  banner <<-EOS
FortiManager API Access

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


################################################################################################################
#myresult = fmgapi.get_adom_by_name(:adom => 'customerA')
#myresult = fmgapi.get_adom_by_oid(:adom => '152')
#myresult = fazapi.get_adom_list
#myresult = fmgapi.get_config({:revision_number => '4', :dev_id => '234'})
#myresult = fmgapi.get_config_revision_history({:dev_id => '234', :min_checkin_date => '20140428', :max_checkin_date => '20140430'})
#myresult = fmgapi.get_device(:serial_number => 'FGVM020000018110')
#myresult = fmgapi.get_device_license_list
#myresult = fazapi.get_device_list
#myresult = fmgapi.get_device_vdom_list(:dev_id => '234')
myresult = fazapi.get_faz_archive({:adom => 'root', :dev_id => 'FWF60D4613000043', :file_name => '1712625325:0', :type => '6'})
#myresult = fazapi.get_faz_archive({:dev_id => 'FWF60D4613000043', :file_name => '1712625325:0', :type => '6'})
#myresult = fazapi.get_faz_config
#myresult = fmgapi.get_fmg_config
#myresult = fazapi.get_faz_generated_report   ### Doesn't work yet, issues with finding report name
#myresult = fmgapi.get_group_list(:adom => 'customerA')
#myresult = fmgapi.get_group({:groupid => '101', :name => 'All_FortiGate', :adom=>'customerA'})
#myresult = fmgapi.get_instlog({:serial_number => 'FGVM020000018110'})
#myresult = fmgapi.get_package_list(:adom => 'customerA')
#myresult = fmgapi.get_script(:script_name => 'cli-sys-status')
#myresult = fmgapi.get_script_log({:script_name => 'cli-sys-status', :sn => 'FGVM020000018110'})
#myresult = fmgapi.get_script_log_summary({:sn => 'FGVM020000018110', :max_logs => '200'})
#myresult = fmgapi.get_system_status()
#myresult = fmgapi.get_task_detail('186', 'customerA')
#myresult = fmgapi.import_policy({:adom_name => 'root', :dev_name => 'MSSP-1', :vdom_name => 'root'})
#myresult = fmgapi.install_config({:adom => 'root', :pkgoid => '572', :dev_id => '234', :rev_name => 'API Install'})
#myresult = fazapi.list_faz_generated_reports({:start_date => '20140401', :end_date => '20140101'})
#myresult = fmgapi.list_revision_id({:dev_id => '234', :rev_name => 'API Install'})
#myresult = fazapi.remove_faz_archive({:adom => 'root', :dev_id => 'FWF60D4613000043', :file_name => '1712625326:0', :type => '6'})
#myresult = fmgapi.retrieve_config({:dev_id => '234', :rev_name => 'API-Retrieve'})
#myresult = fmgapi.revert_config({:rev_id => '4', :dev_id => '234'})
#myresult = fazapi.run_faz_report({:report_template => 'Admin and System Events Report'})




####################################################################################################################
#puts '### DATE TIME STUFF ###'
#testtime = DateTime.parse('04042014 01:10:30').strftime("%Y-%m-%dT%H:%M:%S").to_s rescue false
#puts testtime


#puts DateTime.strptime('2014-04-25T00:00:00', '%Y--%m--%d')

puts myresult.class
puts myresult

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



