require 'spec_helper'

describe HomeController, :type => :controller do

  before do
    @app = init_application
  end

  describe "GET 'index'" do
    it "should be successful" do
      Tr8n.session.with_block_options(:dry => true) do
        get :index
        expect(response).to be_success
      end
    end
  end

end