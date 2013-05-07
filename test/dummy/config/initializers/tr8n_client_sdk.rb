Tr8nClientSdk::Config.models.each do |model|
  model.establish_connection({
    :adapter => 'sqlite3',
    :database => '/Users/michael/Projects/Geni/translation/db/development.sqlite3',
    :pool => 5,
    :timeout => 5000
  })
end
