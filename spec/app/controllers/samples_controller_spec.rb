require 'spec_helper'

describe SamplesController, :type => :controller do

  before do
    @app = init_application
  end

  describe "GET 'language_cases'" do
    it "should be successful" do
      Tr8n.session.with_block_options(:dry => true) do
        get :language_cases
        expect(response).to be_success
      end
    end
  end

end