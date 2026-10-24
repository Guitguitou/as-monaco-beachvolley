# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261023090000_create_terrains_and_reference_them")

# Rejoue la migration sur des données au format de l'ancien enum. Le DDL
# PostgreSQL est transactionnel : la transaction de l'exemple annule tout.
RSpec.describe CreateTerrainsAndReferenceThem do
  let(:connection) { ActiveRecord::Base.connection }
  let(:migration) { described_class.new.tap { |m| m.verbose = false } }
  let(:coach) { create(:user, :coach) }

  before do
    coach
    migration.migrate(:down)
  end

  after do
    connection.schema_cache.clear!
    [ Session, TerrainClosure, Tournament ].each(&:reset_column_information)
  end

  def insert_session(terrain:, hour:)
    connection.select_value(<<~SQL)
      INSERT INTO sessions (title, start_at, end_at, session_type, user_id, terrain, price, created_at, updated_at)
      VALUES ('Legacy', NOW() + INTERVAL '#{hour} hours', NOW() + INTERVAL '#{hour + 1} hours', 'jeu_libre', #{coach.id}, #{terrain || "NULL"}, 0, NOW(), NOW())
      RETURNING id
    SQL
  end

  def insert_closure(terrain:)
    connection.select_value(<<~SQL)
      INSERT INTO terrain_closures (terrain, starts_on, ends_on, created_at, updated_at)
      VALUES (#{connection.quote(terrain)}, CURRENT_DATE, CURRENT_DATE, NOW(), NOW())
      RETURNING id
    SQL
  end

  it "crée les trois terrains et rattache sessions, fermetures et tournois sans toucher aux anciennes colonnes" do
    sessions = { 1 => insert_session(terrain: 1, hour: 1), 2 => insert_session(terrain: 2, hour: 3), 3 => insert_session(terrain: 3, hour: 5) }
    closure = insert_closure(terrain: "Terrain 2")
    tournament = connection.select_value(<<~SQL)
      INSERT INTO tournaments (title, starts_on, ends_on, start_time, end_time, level, price_cents, terrains, created_at, updated_at)
      VALUES ('Open', CURRENT_DATE, CURRENT_DATE, '10:00', '16:00', 'S3', 3000, '{1,3}', NOW(), NOW())
      RETURNING id
    SQL

    migration.migrate(:up)

    expect(connection.select_rows("SELECT id, name, position FROM terrains ORDER BY id"))
      .to eq([ [ 1, "Terrain 1", 1 ], [ 2, "Terrain 2", 2 ], [ 3, "Terrain 3", 3 ] ])
    sessions.each do |terrain, id|
      expect(connection.select_rows("SELECT terrain, terrain_id FROM sessions WHERE id = #{id}")).to eq([ [ terrain, terrain ] ])
    end
    expect(connection.select_rows("SELECT terrain, terrain_id FROM terrain_closures WHERE id = #{closure}")).to eq([ [ "Terrain 2", 2 ] ])
    expect(connection.select_value("SELECT terrains FROM tournaments WHERE id = #{tournament}")).to eq("{1,3}")
  end

  it "reprend la séquence des ids après les terrains insérés" do
    migration.migrate(:up)

    expect(connection.select_value("INSERT INTO terrains (name, position, created_at, updated_at) VALUES ('Terrain 4', 4, NOW(), NOW()) RETURNING id")).to eq(4)
  end

  it "laisse sans terrain une session qui n'en avait pas" do
    id = insert_session(terrain: nil, hour: 1)

    migration.migrate(:up)

    expect(connection.select_value("SELECT terrain_id FROM sessions WHERE id = #{id}")).to be_nil
  end

  it "échoue si une fermeture porte un nom de terrain inconnu" do
    insert_closure(terrain: "Terrain 9")

    expect { migration.migrate(:up) }.to raise_error(/Backfill terrain incomplet : 0 session\(s\), 1 fermeture\(s\)/)
  end

  it "échoue si une session porte une valeur d'enum inconnue" do
    insert_session(terrain: 7, hour: 1)

    expect { migration.migrate(:up) }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
