# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  def promoted_to_main_list(user, session_record)
    assign_session(user, session_record)

    mail(
      to: user.email,
      subject: "Tu passes en liste principale – #{@session_name} du #{@session_date}"
    )
  end

  def displaced_to_waitlist(user, session_record)
    assign_session(user, session_record)

    mail(
      to: user.email,
      subject: "Tu repasses en liste d'attente – #{@session_name} du #{@session_date}"
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

  private

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
