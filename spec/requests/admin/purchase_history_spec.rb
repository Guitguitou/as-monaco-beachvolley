require 'rails_helper'

RSpec.describe "Admin::PurchaseHistories", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:financial_manager) { create(:user, financial_manager: true) }

  describe "GET /admin/purchase_history" do
    context "when user is admin" do
      before { login_as admin_user, scope: :user, scope: :user }

      it "returns http success" do
        get admin_purchase_history_index_path
        expect(response).to have_http_status(:success)
      end

      it "displays purchase history" do
        purchase = create(:credit_purchase, :paid, user: regular_user)
        get admin_purchase_history_index_path
        expect(response.body).to include(purchase.user.full_name)
      end
    end

    context "when user is financial manager" do
      before { login_as financial_manager, scope: :user }

      it "returns http success" do
        get admin_purchase_history_index_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not admin or financial manager" do
      before { login_as regular_user, scope: :user }

      it "redirects with alert" do
        get admin_purchase_history_index_path
        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(flash[:alert]).to eq("Accès interdit")
      end
    end

    context "when user is not signed in" do
      it "redirects to login" do
        get admin_purchase_history_index_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/purchase_history/export" do
    let(:pack) { create(:pack, :credits) }
    let(:start_date) { 1.month.ago.beginning_of_month }
    let(:end_date) { 1.month.ago.end_of_month }

    context "when user is admin" do
      before { login_as admin_user, scope: :user, scope: :user }

      context "with valid dates" do
        let!(:purchase_in_range) do
          create(:credit_purchase, :paid,
                 user: regular_user,
                 pack: pack,
                 created_at: 1.month.ago + 5.days,
                 amount_cents: 2000,
                 credits: 2000)
        end
        let!(:purchase_out_of_range) do
          create(:credit_purchase, :paid,
                 user: regular_user,
                 pack: pack,
                 created_at: 2.months.ago,
                 amount_cents: 1000,
                 credits: 1000)
        end

        it "exports CSV with purchases in date range" do
          get export_admin_purchase_history_index_path,
              params: {
                start_date: start_date.to_s,
                end_date: end_date.to_s,
                format: 'csv'
              }

          expect(response).to have_http_status(:success)
          expect(response.headers['Content-Type']).to include('text/csv')
          expect(response.headers['Content-Disposition']).to include('attachment')
          expect(response.headers['Content-Disposition']).to include('.csv')

          csv_content = response.body
          expect(csv_content).to include('Date')
          expect(csv_content).to include('Utilisateur')
          expect(csv_content).to include('Montant (€)')
          expect(csv_content).to include(purchase_in_range.user.full_name)
          expect(csv_content).to include('20.0') # amount_eur
          # Vérifier que l'achat hors période n'est pas inclus
          # En utilisant une regex pour s'assurer que le nom n'apparaît que dans la ligne de l'achat dans la période
          lines = csv_content.split("\n")
          data_lines = lines.select { |line| line.include?(purchase_out_of_range.user.full_name) }
          expect(data_lines).to be_empty
        end

        it "includes all required columns in CSV" do
          get export_admin_purchase_history_index_path,
              params: {
                start_date: start_date.to_s,
                end_date: end_date.to_s,
                format: 'csv'
              }

          csv_content = response.body
          expect(csv_content).to include('Date')
          expect(csv_content).to include('Heure')
          expect(csv_content).to include('Utilisateur')
          expect(csv_content).to include('Email')
          expect(csv_content).to include('Pack')
          expect(csv_content).to include('Type de pack')
          expect(csv_content).to include('Montant (€)')
          expect(csv_content).to include('Crédits')
          expect(csv_content).to include('Statut')
          expect(csv_content).to include('Référence transaction')
          expect(csv_content).to include('Date de paiement')
        end

        it "includes totals in CSV" do
          get export_admin_purchase_history_index_path,
              params: {
                start_date: start_date.to_s,
                end_date: end_date.to_s,
                format: 'csv'
              }

          csv_content = response.body
          expect(csv_content).to include('TOTAL')
          expect(csv_content).to include('Nombre d\'achats')
        end

        it "handles purchases with user correctly" do
          purchase_with_user = create(:credit_purchase, :paid,
                                     user: regular_user,
                                     pack: pack,
                                     created_at: 1.month.ago + 5.days,
                                     amount_cents: 1500,
                                     credits: 1500)

          get export_admin_purchase_history_index_path,
              params: {
                start_date: start_date.to_s,
                end_date: end_date.to_s,
                format: 'csv'
              }

          csv_content = response.body
          expect(csv_content).to include(regular_user.full_name)
          expect(csv_content).to include(regular_user.email)
        end

        it "handles purchases without pack" do
          purchase_no_pack = create(:credit_purchase, :paid,
                                    user: regular_user,
                                    pack: nil,
                                    created_at: 1.month.ago + 5.days,
                                    amount_cents: 1000,
                                    credits: 1000)

          get export_admin_purchase_history_index_path,
              params: {
                start_date: start_date.to_s,
                end_date: end_date.to_s,
                format: 'csv'
              }

          csv_content = response.body
          expect(csv_content).to include('Achat direct')
        end

        it "translates status correctly" do
          get export_admin_purchase_history_index_path,
              params: {
                start_date: start_date.to_s,
                end_date: end_date.to_s,
                format: 'csv'
              }

          csv_content = response.body
          expect(csv_content).to include('Payé')
        end
      end

      context "with invalid dates" do
        it "redirects with alert when start_date is missing" do
          get export_admin_purchase_history_index_path,
              params: {
                end_date: end_date.to_s,
                format: 'csv'
              }

          expect(response).to redirect_to(admin_purchase_history_index_path)
          expect(flash[:alert]).to eq("Veuillez sélectionner une période valide")
        end

        it "redirects with alert when end_date is missing" do
          get export_admin_purchase_history_index_path,
              params: {
                start_date: start_date.to_s,
                format: 'csv'
              }

          expect(response).to redirect_to(admin_purchase_history_index_path)
          expect(flash[:alert]).to eq("Veuillez sélectionner une période valide")
        end

        it "redirects with alert when start_date is after end_date" do
          get export_admin_purchase_history_index_path,
              params: {
                start_date: end_date.to_s,
                end_date: start_date.to_s,
                format: 'csv'
              }

          expect(response).to redirect_to(admin_purchase_history_index_path)
          expect(flash[:alert]).to eq("La date de début doit être antérieure à la date de fin")
        end

        it "redirects with alert for unsupported format" do
          get export_admin_purchase_history_index_path,
              params: {
                start_date: start_date.to_s,
                end_date: end_date.to_s,
                format: 'xlsx'
              }

          expect(response).to redirect_to(admin_purchase_history_index_path)
          expect(flash[:alert]).to eq("Format d'export non supporté")
        end
      end
    end

    context "when user is financial manager" do
      before { login_as financial_manager, scope: :user }

      it "allows export" do
        get export_admin_purchase_history_index_path,
            params: {
              start_date: start_date.to_s,
              end_date: end_date.to_s,
              format: 'csv'
            }

        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not admin or financial manager" do
      before { login_as regular_user, scope: :user }

      it "redirects with alert" do
        get export_admin_purchase_history_index_path,
            params: {
              start_date: start_date.to_s,
              end_date: end_date.to_s,
              format: 'csv'
            }

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(flash[:alert]).to eq("Accès interdit")
      end
    end
  end
end
