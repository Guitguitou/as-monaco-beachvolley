class ChangeClubEnLibre < ActiveRecord::Migration[8.0]
  def up
    User.where(license_type: "club").update_all(license_type: "libre")
  end
  
  def down
    User.where(license_type: "libre").update_all(license_type: "club")
  end
end
