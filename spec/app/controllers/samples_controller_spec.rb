require 'spec_helper'

describe SamplesController, :type => :controller do

  describe "GET 'language_cases'" do
    it "should be successful" do
      get :language_cases
      expect(response).to be_success
    end
  end

end