# frozen_string_literal: true

# Pagination offset/limit pour une relation ActiveRecord.
#
# Le projet n'embarque aucune gem de pagination : le pattern était recopié à la
# main dans Admin::UsersController. Cette classe l'isole et ne déclenche qu'un
# seul COUNT, contre deux quand la vue rappelait `scope.count` pour afficher le
# total (cf. l'ancien users/_profile_tab).
#
#   page = Pagination.new(scope: user.credit_transactions, page: params[:page])
#   page.records      # la tranche demandée
#   page.total_pages  # 1 minimum, même si vide
class Pagination
  DEFAULT_PER_PAGE = 20

  def initialize(scope:, page: nil, per_page: DEFAULT_PER_PAGE)
    @scope = scope
    @per_page = per_page.to_i.positive? ? per_page.to_i : DEFAULT_PER_PAGE
    @requested_page = page
  end

  def records
    @records ||= scope.offset((current_page - 1) * per_page).limit(per_page).to_a
  end

  def total_count
    @total_count ||= scope.count
  end

  def total_pages
    @total_pages ||= [ (total_count.to_f / per_page).ceil, 1 ].max
  end

  # Bornée à [1, total_pages] : une page hors limites retombe sur la dernière
  # plutôt que d'afficher un tableau vide sans explication.
  def current_page
    @current_page ||= begin
      requested = @requested_page.to_i
      requested = 1 if requested < 1
      [ requested, total_pages ].min
    end
  end

  def next_page
    current_page < total_pages ? current_page + 1 : nil
  end

  def prev_page
    current_page > 1 ? current_page - 1 : nil
  end

  def multiple_pages?
    total_pages > 1
  end

  def empty?
    total_count.zero?
  end

  def any?
    !empty?
  end

  private

  attr_reader :scope, :per_page
end
