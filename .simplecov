SimpleCov.start "rails" do
  enable_coverage :branch

  add_filter "app/channels"
  add_filter "app/jobs/application_job.rb"
  add_filter "app/mailers/application_mailer.rb"

  add_group "Components", "app/components"
  add_group "Presenters", "app/presenters"
  add_group "Queries", "app/queries"
  add_group "Services", "app/services"

  # Seuil aligné sur la couverture atteinte : à remonter au fil des ajouts de
  # specs, jamais à redescendre.
  minimum_coverage line: 79, branch: 62
end
