# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  def promoted_to_main_list(user, session_record)
    @user = user
    @session = session_record
    @session_name = @session.title || @session.session_type.humanize
    @session_date = @session.start_at.strftime("%d/%m/%Y")
    @session_time = @session.start_at.strftime("%Hh%M")
    @session_url = session_url(@session)

    mail(
      to: user.email,
      subject: "Tu passes en liste principale – #{@session_name} du #{@session_date}"
    )
  end

  def session_cancelled(user, session_name:, session_date:)
    @user = user
    @session_name = session_name
    @session_date = session_date
    @sessions_url = sessions_url

    mail(
      to: user.email,
      subject: "Session annulée – #{session_name} du #{session_date}"
    )
  end
end
