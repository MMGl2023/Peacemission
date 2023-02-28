class CreateAnkets < ActiveRecord::Migration[6.0]
  def self.up
    create_table :ankets, :force=>true do |t|
      t.string :first_name
      t.string :second_name
      t.string :last_name
      t.string :girl_family_name
      t.string :nickname
      t.boolean :gender
      t.string :marital_status
      t.date :birth_date
      t.string :birth_place
      t.string :sitizenship
      t.string :ethnicity
      t.text :passport_info
      t.string :military_number
      t.string :residental_address
      t.text :education_info
      t.text :job_info
      t.text :skills_info
      t.text :life_plans
      t.text :military_info1
      t.text :military_info2
      t.text :family_members
      t.text :friends
      t.text :diseases_info1
      t.text :deseases_info2
      t.text :pregnancy_info
      t.string :body_height
      t.string :body_constitution
      t.string :body_corpulence
      t.integer :feet_size
      t.integer :feet_length
      t.integer :blood_group
      t.string :body_pilosis
      t.string :face_pilosis
      t.string :head_hair
      t.string :head_hair_specials
      t.integer :head_size
      t.string :head_form
      t.string :moustache_info
      t.string :skin_color
      t.string :face_sideview, :face_frontview, :face_type
      t.string :face_specials
      t.string :forehead_type
      t.string :forehead_height
      t.string :forehead_specials

      t.string :eyebrow_position
      t.string :eyebrow_type
      t.string :eyebrow_specials

      t.string :eyes_info
      t.string :eyes_specials


      t.timestamps
    end
  end

  def self.down
    drop_table :ankets
  end
end
