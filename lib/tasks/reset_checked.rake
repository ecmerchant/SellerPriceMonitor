namespace :reset_checked do
  desc "チェック状態のクリア"
  task :reset_checked, [:user] => :environment do |task, args|
    cuser = args[:user]
    target = Product.where(user:cuser)
    target.update(checked: false, checked2: false, checked3: false)
    p "//////  Checked is clear //////"
  end
end
