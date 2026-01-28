# frozen_string_literal: true

require 'json'
require 'aws-sdk-ssm'

# Stub the SSM client before loading lambda.rb to prevent AWS connection attempts
SSM_CLIENT_DOUBLE = Aws::SSM::Client.new(stub_responses: true)

# Temporarily replace SSM::Client.new to return our stubbed client
original_new = Aws::SSM::Client.method(:new)
Aws::SSM::Client.define_singleton_method(:new) { |**_| SSM_CLIENT_DOUBLE }

# Load the lambda file
lambda_file = File.expand_path('../src/lambda.rb', __dir__)
load lambda_file

# Restore original behavior
Aws::SSM::Client.define_singleton_method(:new, original_new)

RSpec.describe 'Lambda functions' do
  let(:ssm_client) { instance_double(Aws::SSM::Client) }

  before do
    stub_const('SSM_CLIENT', ssm_client)
  end

  describe '#get_ssm_parameter' do
    it 'retrieves a parameter with decryption enabled' do
      parameter_response = instance_double(
        Aws::SSM::Types::GetParameterResult,
        parameter: instance_double(Aws::SSM::Types::Parameter, value: 'secret-value')
      )

      expect(ssm_client).to receive(:get_parameter).with(
        name: '/test/parameter',
        with_decryption: true
      ).and_return(parameter_response)

      result = get_ssm_parameter('/test/parameter')
      expect(result).to eq(parameter_response)
    end
  end

  describe '#update_ssm_parameter' do
    it 'updates a parameter with overwrite enabled' do
      expect(ssm_client).to receive(:put_parameter).with(
        name: '/test/parameter',
        overwrite: true,
        value: 'new-value'
      )

      update_ssm_parameter('/test/parameter', 'new-value')
    end
  end

  describe '#github_token_from_ssm' do
    before do
      allow(ENV).to receive(:fetch).with('GITHUB_TOKEN_SSM_PATH', nil).and_return('/github/token/path')
    end

    it 'returns the GitHub token from SSM' do
      parameter_response = instance_double(
        Aws::SSM::Types::GetParameterResult,
        parameter: instance_double(Aws::SSM::Types::Parameter, value: 'ghp_test_token')
      )

      expect(ssm_client).to receive(:get_parameter).with(
        name: '/github/token/path',
        with_decryption: true
      ).and_return(parameter_response)

      expect(github_token_from_ssm).to eq('ghp_test_token')
    end
  end

  describe '#last_time_checked_from_ssm' do
    before do
      allow(ENV).to receive(:fetch).with('LAST_TIME_CHECKED_SSM_PATH', nil).and_return('/last/checked/path')
    end

    context 'when parameter has a valid timestamp' do
      it 'returns the stored timestamp' do
        stored_time = '2025-01-15T10:30:00.000+00:00'
        parameter_response = instance_double(
          Aws::SSM::Types::GetParameterResult,
          parameter: instance_double(Aws::SSM::Types::Parameter, value: stored_time)
        )

        expect(ssm_client).to receive(:get_parameter).with(
          name: '/last/checked/path',
          with_decryption: true
        ).and_return(parameter_response)

        expect(last_time_checked_from_ssm).to eq(stored_time)
      end
    end

    context 'when parameter value is "null"' do
      it 'returns a timestamp from 1 day ago' do
        parameter_response = instance_double(
          Aws::SSM::Types::GetParameterResult,
          parameter: instance_double(Aws::SSM::Types::Parameter, value: 'null')
        )

        expect(ssm_client).to receive(:get_parameter).with(
          name: '/last/checked/path',
          with_decryption: true
        ).and_return(parameter_response)

        frozen_time = DateTime.new(2025, 1, 28, 12, 0, 0)
        allow(DateTime).to receive(:now).and_return(frozen_time)

        result = last_time_checked_from_ssm
        expected_time = (frozen_time - 1).iso8601(3)

        expect(result).to eq(expected_time)
      end
    end
  end
end
