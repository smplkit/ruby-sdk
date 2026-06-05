.PHONY: install generate test lint \
	config_runtime_showcase config_management_showcase \
	flags_runtime_showcase flags_management_showcase \
	logging_runtime_showcase logging_management_showcase \
	audit_runtime_showcase audit_management_showcase \
	jobs_management_showcase

install:
	bundle install

generate:
	bash scripts/generate.sh

test:
	bundle exec rspec

lint:
	bundle exec rubocop

config_runtime_showcase: install
	bundle exec ruby examples/config_runtime_showcase.rb

config_management_showcase: install
	bundle exec ruby examples/config_management_showcase.rb

flags_runtime_showcase: install
	bundle exec ruby examples/flags_runtime_showcase.rb

flags_management_showcase: install
	bundle exec ruby examples/flags_management_showcase.rb

logging_runtime_showcase: install
	bundle exec ruby examples/logging_runtime_showcase.rb

logging_management_showcase: install
	bundle exec ruby examples/logging_management_showcase.rb

audit_runtime_showcase: install
	bundle exec ruby examples/audit_runtime_showcase.rb

audit_management_showcase: install
	bundle exec ruby examples/audit_management_showcase.rb

jobs_management_showcase: install
	bundle exec ruby examples/jobs_management_showcase.rb
