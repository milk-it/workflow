# Coverage test
begin
  require 'rcov/rcovtask'

  TESTS = ["units", "functionals", "integration"]

  def add_options(rcov)
    rcov.rcov_opts.push("--rails")
    rcov.rcov_opts.push(ENV['rcov']) if ENV['rcov']
  end

  namespace :test do
    desc "Coverage on unit, functional and integration tests"
    Rcov::RcovTask.new(:coverage) do |rcov|
      rcov.libs.push("test")
      add_options(rcov)
      rcov.test_files = Dir["test/{#{TESTS.join(',').gsub(/s,/, ',')}}/*_test.rb"]
    end

    TESTS.each do |test|
      desc "Coverage on #{test} tests"
      Rcov::RcovTask.new("#{test}:coverage") do |rcov|
        rcov.libs.push("test")
        add_options(rcov)
        rcov.test_files = Dir["test/#{test}/*_test.rb"]
      end
    end
  end
rescue
  puts "No rcov found"
end
