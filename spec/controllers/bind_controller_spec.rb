require 'spec_helper'

RSpec.describe BindController, type: :request do
  let(:username) { ENV['SECURITY_USER_NAME'] }
  let(:password) { ENV['SECURITY_USER_PASSWORD'] }

  let(:legacy_params) do
    {
      service_id: 'c024e536-6dc4-45c6-8a53-127e7f8275ab',
      plan_id: '3a116ac2-fc8b-496f-a715-e9a1b205d05c.community',
      context: {
        platform: 'cloudfoundry'
      },
      bind_resource: {
        app_guid: 'test_app'
      }
    }
  end

  let(:params) do 
    legacy_params.merge({
      context: {
        organization_guid: 'test_org',
        space_guid: 'test_space'
      }
    })
  end

  let(:headers) do
    {
      'X-Broker-API-Version' => '2.13',
      'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    }
  end

  describe 'PUT' do
    before do
      # Assume V5 unless otherwise set
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('CONJUR_VERSION').and_return('5')
    end

    context 'when the app cf context is not present' do
      it "does not ensure the policy structure exists" do
        expect_any_instance_of(OrgSpacePolicy).to_not receive(:ensure_exists)
        expect_any_instance_of(ServiceBinding).to receive(:create)
        
        put('/v2/service_instances/test_instance/service_bindings/test_binding', 
          params: legacy_params, headers: headers)

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:created)
      end
    end

    context 'when the app cf context is present' do
      it "ensures the policy structure exists" do
        expect_any_instance_of(OrgSpacePolicy).to receive(:ensure_exists)
        expect_any_instance_of(ServiceBinding).to receive(:create)

        put('/v2/service_instances/test_instance/service_bindings/test_binding', 
          params: params, headers: headers)

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:created)
      end

      context 'when using Conjur V4' do
        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('CONJUR_VERSION').and_return('4')
        end

        it "does not ensure the policy structure exists" do
          expect_any_instance_of(OrgSpacePolicy).to_not receive(:ensure_exists)
          expect_any_instance_of(ServiceBinding).to receive(:create)
  
          put('/v2/service_instances/test_instance/service_bindings/test_binding', 
            params: params, headers: headers)
  
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
        end
      end
    end
  end
end
