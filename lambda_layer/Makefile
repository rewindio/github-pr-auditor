# SAM does not package ruby layers correctly
# AWS Lambda has a GEM_PATH of:
# /var/task/vendor/bundle/ruby/3.2.0:/opt/ruby/gems/3.2.0
# but the layer is zipped up as: /opt/ruby/3.2.0/gems
#
# See: https://github.com/aws/aws-lambda-builders/issues/177
# and: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/building-custom-runtimes.html

RUBY_VERSION = 3.2.0

mkfile_path := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))

build-AuditorLambdaLayer:
	rm  -rf $(mkfile_path)/ruby
	bundle config --local path $(mkfile_path)
	bundle install
	rm -rf $(mkfile_path)/ruby/$(RUBY_VERSION)/cache && rm -rf $(mkfile_path)/ruby/$(RUBY_VERSION)/bin
	mkdir -p $(mkfile_path)/ruby/gems
	mv $(mkfile_path)/ruby/$(RUBY_VERSION) $(mkfile_path)/ruby/gems
