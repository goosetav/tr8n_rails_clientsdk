# encoding: UTF-8

require 'helper'

describe Tr8n::Application do
  describe "#configuration" do
    it "sets class attributes" do
      expect(Tr8n::Application.attributes).to eq([:host, :key, :secret, :access_token, :name, :description, :threshold, :default_locale, :default_level, :features, :languages, :sources, :components, :tokens])
    end
  end

  describe "#initialize" do
    before do
      @app = init_application
    end

    it "loads application attributes" do
      expect(@app.key).to eq("default")
      expect(@app.name).to eq("Tr8n Translation Service")

      expect(@app.default_data_token('nbsp')).to eq("&nbsp;")
      expect(@app.default_decoration_token('strong')).to eq("<strong>{$0}</strong>")

      expect(@app.feature_enabled?(:language_cases)).to be_true
      expect(@app.feature_enabled?(:language_flags)).to be_true
    end

    it "loads application language" do
      expect(@app.languages.size).to eq(13)

      russian = @app.language('ru')
      expect(russian.locale).to eq('ru')
      expect(russian.contexts.keys.size).to eq(6)
      expect(russian.contexts.keys).to eq(["date", "gender", "genders", "list", "number", "value"])
    end
  end

end