# frozen_string_literal: true

# Remplace des variables d'environnement le temps d'un exemple.
#
# Préférable à un stub de `ENV.fetch` : le stub casse dès que le code sous test
# lit une autre clé que celles prévues, et il oblige à lister par avance chaque
# lecture d'environnement traversée.
module EnvHelper
  def with_env(values)
    previous = values.keys.index_with { |key| ENV[key] }
    values.each { |key, value| assign_env(key, value) }

    yield
  ensure
    previous.each { |key, value| assign_env(key, value) }
  end

  private

  def assign_env(key, value)
    value.nil? ? ENV.delete(key) : ENV[key] = value
  end
end

RSpec.configure do |config|
  config.include EnvHelper
end
