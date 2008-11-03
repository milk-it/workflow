# Coverage test
begin
  TESTS = ["unit", "functional", "integration"]
  require 'rcov/rcovtask'

  namespace :test do
    desc "Coverage on unit, functional and integration tests"
    Rcov::RcovTask.new(:coverage) do |rcov|
      rcov.libs.push("test")
      rcov.rcov_opts.push("--rails")
      rcov.test_files = Dir["test/{#{TESTS.join(",")}}/*_test.rb"]
    end

    TESTS.each do |test|
      desc "Coverage on #{test} tests"
      Rcov::RcovTask.new("#{test}s:coverage") do |rcov|
        rcov.libs.push("test")
        rcov.rcov_opts.push("--rails")
        rcov.test_files = Dir["test/#{test}/*_test.rb"]
      end
    end
  end
rescue
  puts "No rcov found"
end
