# Coverage test
TESTS = ["unit", "functional", "integration"]
RCOV = "rcov --rails --text-summary -Ilib #{ENV["HTML"].nil? || ENV["HTML"].eql?("true") ? "--html" : "--no-html"}"
namespace :test do
  desc "Coverage on unit, functional and integration tests"
  task :coverage do
    rm_f "coverage"
    files = ENV["TEST"].nil?? Dir["test/{#{TESTS.join(",")}}/*_test.rb"].join(" ") : ENV["TEST"]
    system "#{RCOV} #{files}"
  end

  TESTS.each do |test|
      desc "Coverage on #{test} tests"
      task "#{test}s:coverage" do
        rm_f "coverage" # remove old coverage reports
        files = ENV["TEST"].nil?? Dir["test/#{test}/*_test.rb"].join(" ") : ENV["TEST"]
        system "#{RCOV} #{_html} #{files}"
      end
  end
end
