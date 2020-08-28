# encoding: UTF-8
# frozen_string_literal: true

describe API::V2::Admin::WithdrawLimits, type: :request do

  let(:admin) { create(:member, :admin, :level_3, email: 'example@gmail.com', uid: 'ID73BF61C8H0') }
  let(:token) { jwt_for(admin) }
  let(:level_3_member) { create(:member, :level_3) }
  let(:level_3_member_token) { jwt_for(level_3_member) }

  describe 'GET /withdraw_limits' do
    before do
      create(:withdraw_limit, limit_24_hour: 100, limit_1_month: 1000, kyc_level: 2, currency_id: :btc, group: 'vip-0')
      create(:withdraw_limit, limit_24_hour: 50, limit_1_month: 500, kyc_level: 1, currency_id: :any, group: 'vip-0')
      create(:withdraw_limit, limit_24_hour: 50, limit_1_month: 500, kyc_level: 1, currency_id: :btc, group: :any)
    end

    it 'returns all withdraw limits' do
      api_get '/api/v2/admin/withdraw_limits', token: token

      expect(response.status).to eq 200
      expect(JSON.parse(response.body).length).to eq WithdrawLimit.count
    end

    it 'pagination' do
      api_get '/api/v2/admin/withdraw_limits', token: token, params: { limit: 1 }
      expect(JSON.parse(response.body).length).to eq 1
    end

    it 'filters by currency_id' do
      api_get '/api/v2/admin/withdraw_limits', token: token, params: { currency_id: 'btc' }

      result = JSON.parse(response.body)
      expect(result.map { |r| r['currency_id'] }).to all eq 'btc'
      expect(result.length).to eq WithdrawLimit.where(currency_id: 'btc').count
    end

    it 'filters by group' do
      api_get '/api/v2/admin/withdraw_limits', token: token, params: { group: 'vip-0' }

      result = JSON.parse(response.body)
      expect(result.map { |r| r['group'] }).to all eq 'vip-0'
      expect(result.length).to eq WithdrawLimit.where(group: 'vip-0').count
    end

    it 'filters by kyc_level' do
      api_get '/api/v2/admin/withdraw_limits', token: token, params: { kyc_level: '1' }

      result = JSON.parse(response.body)
      expect(result.map { |r| r['kyc_level'] }).to all eq '1'
      expect(result.length).to eq WithdrawLimit.where(kyc_level: '1').count
    end

    it 'capitalized group' do
      api_get '/api/v2/admin/withdraw_limits', token: token, params: { group: 'Vip-0' }

      result = JSON.parse(response.body)
      expect(result.map { |r| r['group'] }).to all eq 'vip-0'
      expect(result.length).to eq WithdrawLimit.where(group: 'vip-0').count
    end
  end

  describe 'POST /withdraw_limits/new' do
    it 'creates a table with default group' do
      api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { limit_24_hour: 100, limit_1_month: 1000, currency_id: 'btc' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['limit_24_hour']).to eq('100.0')
      expect(JSON.parse(response.body)['limit_1_month']).to eq('1000.0')
      expect(JSON.parse(response.body)['group']).to eq('any')
      expect(JSON.parse(response.body)['currency_id']).to eq('btc')
      expect(JSON.parse(response.body)['kyc_level']).to eq('any')
    end

    it 'creates a table with default currency' do
      api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { group: 'vip-1', limit_24_hour: 100, limit_1_month: 1000 }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['limit_24_hour']).to eq('100.0')
      expect(JSON.parse(response.body)['limit_1_month']).to eq('1000.0')
      expect(JSON.parse(response.body)['group']).to eq('vip-1')
      expect(JSON.parse(response.body)['currency_id']).to eq('any')
      expect(JSON.parse(response.body)['kyc_level']).to eq('any')
    end

    it 'creates a table with default kyc_level' do
      api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { group: 'vip-1', limit_24_hour: 100, limit_1_month: 1000 }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['limit_24_hour']).to eq('100.0')
      expect(JSON.parse(response.body)['limit_1_month']).to eq('1000.0')
      expect(JSON.parse(response.body)['group']).to eq('vip-1')
      expect(JSON.parse(response.body)['currency_id']).to eq('any')
      expect(JSON.parse(response.body)['kyc_level']).to eq('any')
    end

    it 'returns created withdraw limit table' do
      api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { kyc_level: 4, group: 'vip-1', currency_id: 'btc', limit_24_hour: 100, limit_1_month: 1000 }

      expect(response).to have_http_status(201)
      expect(JSON.parse(response.body)['limit_24_hour']).to eq('100.0')
      expect(JSON.parse(response.body)['limit_1_month']).to eq('1000.0')
      expect(JSON.parse(response.body)['group']).to eq('vip-1')
      expect(JSON.parse(response.body)['currency_id']).to eq('btc')
      expect(JSON.parse(response.body)['kyc_level']).to eq('4')
    end

    context 'returns created withdraw limit table without group' do
      it 'returns created withdraw limit table' do
        api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { currency_id: 'btc', limit_24_hour: 100, limit_1_month: 1000 }

        expect(response).to have_http_status(201)
        expect(JSON.parse(response.body)['limit_24_hour']).to eq('100.0')
        expect(JSON.parse(response.body)['limit_1_month']).to eq('1000.0')
        expect(JSON.parse(response.body)['group']).to eq('any')
        expect(JSON.parse(response.body)['currency_id']).to eq('btc')
        expect(JSON.parse(response.body)['kyc_level']).to eq('any')
      end
    end

    context 'returns created withdraw limit table without currency_id' do
      it 'returns created withdraw limit table' do
        api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { limit_24_hour: 100, limit_1_month: 1000, group: 'vip-1' }

        expect(response).to have_http_status(201)
        expect(JSON.parse(response.body)['limit_24_hour']).to eq('100.0')
        expect(JSON.parse(response.body)['limit_1_month']).to eq('1000.0')
        expect(JSON.parse(response.body)['group']).to eq('vip-1')
        expect(JSON.parse(response.body)['currency_id']).to eq('any')
        expect(JSON.parse(response.body)['kyc_level']).to eq('any')
      end
    end

    context 'returns created withdraw limit table without kyc_level' do
      it 'returns created withdraw limit table' do
        api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { limit_24_hour: 100, limit_1_month: 1000, group: 'vip-1' }

        expect(response).to have_http_status(201)
        expect(JSON.parse(response.body)['limit_24_hour']).to eq('100.0')
        expect(JSON.parse(response.body)['limit_1_month']).to eq('1000.0')
        expect(JSON.parse(response.body)['group']).to eq('vip-1')
        expect(JSON.parse(response.body)['currency_id']).to eq('any')
        expect(JSON.parse(response.body)['kyc_level']).to eq('any')
      end
    end

    context 'invalid currency_id' do
      it 'returns status 422 and error' do
        api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { limit_24_hour: 100, limit_1_month: 1000, currency_id: 'uah' }

        expect(response).to have_http_status(422)
        expect(response).to include_api_error('admin.withdraw_limit.currency_doesnt_exist')
      end
    end

    context 'empty limit_24_hour field' do
      it 'returns status 422 and error' do
        api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { limit_1_month: 1000, group: 'vip-1', currency_id: 'btc' }

        expect(response).to have_http_status(422)
        expect(response).to include_api_error('admin.withdraw_limit.invalid_limit_24_hour')
      end
    end

    context 'empty limit_1_month field' do
      it 'returns status 422 and error' do
        api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { limit_24_hour: 1000, group: 'vip-1', currency_id: 'btc' }

        expect(response).to have_http_status(422)
        expect(response).to include_api_error('admin.withdraw_limit.invalid_limit_1_month')
      end
    end

    context 'invalid limit_24_hour/limit_1_month value' do
      it 'returns status 422 and error' do
        api_post '/api/v2/admin/withdraw_limits/new', token: token, params: { limit_1_month: -1, limit_24_hour: -15, group: 'vip-1', currency_id: 'btc' }

        expect(response).to have_http_status(422)
        expect(response).to include_api_error('admin.withdraw_limit.invalid_limit_24_hour')
        expect(response).to include_api_error('admin.withdraw_limit.invalid_limit_1_month')
      end
    end
  end

  describe 'POST /withdraw_limits/update' do
    it 'returns updated withdraw limit table with new kyc_level' do
      api_post '/api/v2/admin/withdraw_limits/update', token: token, params: { kyc_level: '3', id: WithdrawLimit.first.id }

      expect(response).to have_http_status(201)
      expect(JSON.parse(response.body)['limit_24_hour']).to eq('9999.0')
      expect(JSON.parse(response.body)['limit_1_month']).to eq('999999.0')
      expect(JSON.parse(response.body)['group']).to eq('any')
      expect(JSON.parse(response.body)['currency_id']).to eq('any')
      expect(JSON.parse(response.body)['kyc_level']).to eq('3')
    end

    it 'returns updated withdraw limit table with new group' do
      api_post '/api/v2/admin/withdraw_limits/update', token: token, params: { group: 'vip-1', id: WithdrawLimit.first.id }

      expect(response).to have_http_status(201)
      expect(JSON.parse(response.body)['limit_24_hour']).to eq('9999.0')
      expect(JSON.parse(response.body)['limit_1_month']).to eq('999999.0')
      expect(JSON.parse(response.body)['group']).to eq('vip-1')
      expect(JSON.parse(response.body)['currency_id']).to eq('any')
      expect(JSON.parse(response.body)['kyc_level']).to eq('any')
    end

    it 'returns updated withdraw limit table with new group with capitalized letter' do
      api_post '/api/v2/admin/withdraw_limits/update', token: token, params: { group: 'Vip-1 ', id: WithdrawLimit.first.id }

      expect(response).to have_http_status(201)
      expect(JSON.parse(response.body)['limit_24_hour']).to eq('9999.0')
      expect(JSON.parse(response.body)['limit_1_month']).to eq('999999.0')
      expect(JSON.parse(response.body)['group']).to eq('vip-1')
      expect(JSON.parse(response.body)['currency_id']).to eq('any')
      expect(JSON.parse(response.body)['kyc_level']).to eq('any')
    end

    it 'returns updated withdraw limit table with new limit_24_hour' do
      api_post '/api/v2/admin/withdraw_limits/update', token: token, params: { currency_id: 'btc', id: WithdrawLimit.first.id }

      expect(response).to have_http_status(201)
      expect(JSON.parse(response.body)['limit_24_hour']).to eq('9999.0')
      expect(JSON.parse(response.body)['limit_1_month']).to eq('999999.0')
      expect(JSON.parse(response.body)['group']).to eq('any')
      expect(JSON.parse(response.body)['currency_id']).to eq('btc')
      expect(JSON.parse(response.body)['kyc_level']).to eq('any')
    end

    it 'returns updated withdraw limit table with new limit_24_hour, limit_1_month fields' do
      api_post '/api/v2/admin/withdraw_limits/update', token: token, params: { limit_24_hour: 10, limit_1_month: 100, id: WithdrawLimit.first.id }

      expect(response).to have_http_status(201)
      expect(JSON.parse(response.body)['limit_24_hour']).to eq('10.0')
      expect(JSON.parse(response.body)['limit_1_month']).to eq('100.0')
      expect(JSON.parse(response.body)['group']).to eq('any')
      expect(JSON.parse(response.body)['currency_id']).to eq('any')
      expect(JSON.parse(response.body)['kyc_level']).to eq('any')
    end

    context 'not found withdraw_limit table' do
      it 'returns status 404 and error' do
        api_post '/api/v2/admin/withdraw_limits/update', token: token, params: { id: 100 }

        expect(response).to have_http_status(404)
        expect(response).to include_api_error('record.not_found')
      end
    end

    context 'empty limit_24_hour type' do
      it 'returns status 422 and error' do
        api_post '/api/v2/admin/withdraw_limits/update', token: token, params: { limit_24_hour: -1, id: WithdrawLimit.first.id }

        expect(response).to have_http_status(422)
        expect(response).to include_api_error('admin.withdraw_limit.invalid_limit_24_hour')
      end
    end

    context 'empty limit_1_month type' do
      it 'returns status 422 and error' do
        api_post '/api/v2/admin/withdraw_limits/update', token: token, params: { limit_1_month: -1, id: WithdrawLimit.first.id }

        expect(response).to have_http_status(422)
        expect(response).to include_api_error('admin.withdraw_limit.invalid_limit_1_month')
      end
    end

    context 'invalid limit_24_hour/limit_1_month type' do
      it 'returns status 422 and error' do
        api_post '/api/v2/admin/withdraw_limits/update', token: token, params: { currency_id: 'uahusd', id: WithdrawLimit.first.id }

        expect(response).to have_http_status(422)
        expect(response).to include_api_error('admin.withdraw_limit.currency_doesnt_exist')
      end
    end
  end

  describe 'POST /withdraw_limits/delete' do
    let!(:withdraw_limit) { create(:withdraw_limit, kyc_level: 1) }

    it 'requires id' do
      api_post '/api/v2/admin/withdraw_limits/delete', token: token
      expect(response).to include_api_error 'admin.withdrawlimit.missing_id'
    end

    it 'deletes withdraw limit table' do
      expect {
        api_post '/api/v2/admin/withdraw_limits/delete', token: token, params: { id: withdraw_limit.id }
      }.to change { WithdrawLimit.count }.by(-1)

      expect(response).to have_http_status(201)
    end

    it 'returns deleted withdraw limit table' do
      api_post '/api/v2/admin/withdraw_limits/delete', token: token, params: { id: withdraw_limit.id }

      expect(JSON.parse(response.body)['id']).to eq withdraw_limit.id
    end

    it 'retuns 404 if record does not exist' do
      expect {
        api_post '/api/v2/admin/withdraw_limits/delete', token: token, params: { id: WithdrawLimit.last.id + 42 }
      }.not_to change { WithdrawLimit.count }

      expect(response.status).to eq 404
    end
  end
end
