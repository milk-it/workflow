# thanks rails ;)
module Kernel
  def silence_stderr
    old_stderr = STDERR.dup
    STDERR.reopen(RUBY_PLATFORM =~ /(:?mswin|mingw)/ ? 'NUL:' : '/dev/null')
    STDERR.sync = true
    yield
  ensure
    STDERR.reopen(old_stderr)
  end
end

namespace :svn do
  # TODO: test coverage for at least 90%
  desc "Commit the project if all tests pass, also run the svn:add task"
  task :commit => [:test, :add] do
    system("svn", "commit")
  end
  task :ci => [:commit]

  desc "Add files that were not added to the Subversion repository"
  task :add do
    status = silence_stderr { `svn st` }
    # Scan all and remove swap files
    to_add = status.scan(/^\?[ \t]*(.*)$/).delete_if { |f| f[0] =~ /\..*\.swp$/ }

    if to_add.size > 0
      loop do
        add = ask = false
        print("There are files out of versioning, (s)how all, (a)dd all, Ask on (e)ach, (d)on't add: ")

        case STDIN.gets.chomp()[0,1].downcase
        when "s"
          puts to_add
        when "d"
          break
        when "a"
          add = true
          ask = false
        when "e"
          add = true
          ask = true
        end

        if add
          for f in to_add
            f = f[0]
            add_f = add
            if ask
              print "Add #{f} ? "
              add_f = STDIN.gets.chomp()[0,1].downcase.eql?("y")
            end
            system("svn", "add", f) if add_f
          end
          break
        end
      end
    end
  end

  # thanks to appelsiini.net
  desc "Prepare the project for subversion"
  task :prepare do
    ignores = {}
    tasks_before = []
    tasks_after = []

    puts("** Ignoring logs")
    tasks_before.push("svn del log/* --force")
    ignores["log/"] = "*.log"

    puts("** Ignoring sessions")
    tasks_before.push("svn del tmp/sessions/* --force")
    ignores["tmp/sessions/"] = "*"

    puts("** Ignoring dbs")
    tasks_before.push("svn del db/*.db --force")
    ignores["db/"] = "*.db"

    puts("** Ignoring database.yml")
    tasks_before.push("svn mv config/database.yml config/database.example")
    ignores["config/"] = "database.yml"

    puts("** Ignoring coverage reports")
    if silence_stderr { system("ls coverage") }
      tasks_before.push("mv coverage rcoverage")
      tasks_after.push("mv rcoverage coverage")
    end
    ignores["."] = "coverage"

    puts("** Ignoring NetBeans and Eclipse project files")
    if silence_stderr { system("ls .project") }
      tasks_before.push("mv .project eclipse")
      tasks_before.push("svn del .project --force")
      tasks_after.push("mv eclipse .project")
    end
    if silence_stderr { system("ls nbproject") }
      tasks_before.push("mv nbproject netbeans") 
      tasks_before.push("svn del nbproject --force")
      tasks_after.push("mv netbeans nbproject")
    end
    ignores["."] += "\nnbproject\n.project"

    silence_stderr {
      tasks_before.each { |task| system(task) }

      ignores.each { |path, files| system("svn", "propset", "svn:ignore", files, path) }
    
      system("svn", "commit", "-m", "\"Ignoring database.yml and creating an example file; Ignoring all files in /log/ ending in .log; Ignoring all files in /db/ ending in .db\" config/ db/ log/ tmp/sessions/; Ignoring coverage reports\"")
      
      system("svn", "update")

      tasks_after.each { |task| system(task) }
    }
  end

  desc "Display the changes SINCE a revision (rake svn:changes SINCE=revision_number)"
  task :changes do
    puts("Please, provide SINCE variable") and exit unless ENV['SINCE']
    changes = silence_stderr { `svn log -r#{ENV['SINCE']}:HEAD -v` }
    puts(changes.scan(/^ +(?:[^D]) (.+)/).flatten.uniq.sort)
  end
end
