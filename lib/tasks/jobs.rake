namespace :jobs do
  task parse_news: :environment do
    Parser.run
  end
end