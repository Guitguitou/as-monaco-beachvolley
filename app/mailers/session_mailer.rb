# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  def promoted_to_main_list(user, session_record)
    mail_about_session(user, session_record, "Tu passes en liste principale")
  end

  def displaced_to_waitlist(user, session_record)
    mail_about_session(user, session_record, "Tu repasses en liste d'attente")
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

  private

  def mail_about_session(user, session_record, headline)
    assign_session(user, session_record)
    mail(to: user.email, subject: "#{headline} – #{@session_name} du #{@session_date}")
  end

  def assign_session(user, session_record)
    @user = user
    @session = session_record
    label = Sessions::NotificationLabel.new(@session)
    @session_name = label.name
    @session_date = label.date
    @session_time = label.time
    @session_url = session_url(@session)
  end
end
