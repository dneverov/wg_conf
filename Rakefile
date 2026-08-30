require 'rake/testtask'

task default: :test

# Запуск вообще всех тестов: rake test
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

# Разделение по категориям через namespace
namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.libs << 'test'
    t.pattern = 'test/units/**/*_test.rb'
    t.verbose = false
  end

  Rake::TestTask.new(:integration) do |t|
    t.libs << 'test'
    t.pattern = 'test/integration/**/*_test.rb'
    t.verbose = false
  end
end
