# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::PriorityBalancerService, type: :service do
  # Groupes hiérarchisés : G1 (prioritaire) > G2 > G3
  let(:g1) { create(:level, name: "G1", gender: "male") }
  let(:g2) { create(:level, name: "G2", gender: "male") }
  let(:g3) { create(:level, name: "G3", gender: "male") }

  let(:session_record) { create(:session, max_players: 2, price: 400) }

  # Un joueur crédité, rattaché à un groupe donné
  def player(level, credits: 1000)
    user = create(:user)
    create(:credit_transaction, user: user, amount: credits)
    create(:user_level, user: user, level: level)
    user
  end

  before do
    create(:session_level, session: session_record, level: g1, priority: 1)
    create(:session_level, session: session_record, level: g2, priority: 2)
    create(:session_level, session: session_record, level: g3, priority: 3)
    allow(SendPushNotificationJob).to receive(:perform_later)
  end

  def balance_of(user)
    user.balance.reload.amount
  end

  describe "déplacement d'un secondaire par un prioritaire" do
    it "confirme le G1 et repousse le G3 le plus récent en liste d'attente, remboursé et notifié" do
      g3a = player(g3)
      g3b = player(g3)
      reg_g3a = create(:registration, user: g3a, session: session_record, status: :confirmed)
      reg_g3b = create(:registration, user: g3b, session: session_record, status: :confirmed)
      # les deux G3 ont payé
      Sessions::PriorityBalancerService.call(session: session_record) # no-op, session pleine et pas de prioritaire

      g1_user = player(g1)
      reg_g1 = create(:registration, user: g1_user, session: session_record, status: :waitlisted)

      expect(SessionMailer).to receive(:displaced_to_waitlist).with(g3b, session_record).and_return(double(deliver_later: true))

      Sessions::PriorityBalancerService.call(session: session_record)

      expect(reg_g1.reload).to be_confirmed
      expect(reg_g3a.reload).to be_confirmed
      expect(reg_g3b.reload).to be_waitlisted
      # G3b remboursé (repart en liste d'attente), G1 débité
      expect(SendPushNotificationJob).to have_received(:perform_later).with(
        g3b.id, hash_including(title: "Tu repasses en liste d'attente")
      )
    end

    it "un G2 déplace un G3 mais pas un G1" do
      g1_user = player(g1)
      g3_user = player(g3)
      reg_g1 = create(:registration, user: g1_user, session: session_record, status: :confirmed)
      reg_g3 = create(:registration, user: g3_user, session: session_record, status: :confirmed)

      g2_user = player(g2)
      create(:registration, user: g2_user, session: session_record, status: :waitlisted)

      allow(SessionMailer).to receive(:displaced_to_waitlist).and_return(double(deliver_later: true))
      Sessions::PriorityBalancerService.call(session: session_record)

      expect(reg_g1.reload).to be_confirmed          # G1 conservé
      expect(reg_g3.reload).to be_waitlisted          # G3 déplacé
      expect(g2_user.registrations.find_by(session: session_record)).to be_confirmed
    end
  end

  describe "re-promotion quand une place se libère" do
    it "promeut le waitlisté le plus prioritaire" do
      g1_user = player(g1)
      g2_user = player(g2)
      g3_user = player(g3)
      reg_g1 = create(:registration, user: g1_user, session: session_record, status: :confirmed)
      create(:registration, user: g2_user, session: session_record, status: :confirmed)
      reg_g3 = create(:registration, user: g3_user, session: session_record, status: :waitlisted)
      reg_g2b_user = player(g2)
      reg_g2b = create(:registration, user: reg_g2b_user, session: session_record, status: :waitlisted)

      allow(SessionMailer).to receive(:promoted_to_main_list).and_return(double(deliver_later: true))

      reg_g1.destroy!
      Sessions::PriorityBalancerService.call(session: session_record)

      # entre les deux waitlistés (G3 et G2b), le G2 est plus prioritaire → promu
      expect(reg_g2b.reload).to be_confirmed
      expect(reg_g3.reload).to be_waitlisted
    end
  end

  describe "crédits insuffisants" do
    it "laisse la place au candidat solvable suivant" do
      g1_broke = player(g1, credits: 100) # < 400
      g2_user = player(g2)
      reg_g1 = create(:registration, user: g1_broke, session: session_record, status: :waitlisted)
      reg_g2 = create(:registration, user: g2_user, session: session_record, status: :confirmed)

      allow(SessionMailer).to receive(:promoted_to_main_list).and_return(double(deliver_later: true))
      Sessions::PriorityBalancerService.call(session: session_record)

      # G1 insolvable reste en attente, G2 confirmé conservé
      expect(reg_g1.reload).to be_waitlisted
      expect(reg_g2.reload).to be_confirmed
    end
  end
end
