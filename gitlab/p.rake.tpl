namespace :gitlab do
  namespace :gitolite do
    def gitolite_user_home
      "@H@"
    end
    def gitolite_version
      "v3.2"
    end
  end
  namespace :app do
    def check_init_script_exists
      print "Init script exists? ... "

      script_path = "@H@/gitlab/gitlabd"

      if File.exists?(script_path)
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Install the init script"
        )
        for_more_information(
          see_installation_guide_section "Install Init Script"
        )
        fix_and_rerun
      end
    end
    def check_init_script_up_to_date
      print "Init script up-to-date? ... "
      script_path = "@H@/gitlab/gitlabd"
      unless File.exists?(script_path)
        puts "can't check because of previous errors".magenta
        return
      end
      puts "yes".green
    end
  end
end
