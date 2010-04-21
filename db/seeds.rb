

## ROLES
{ :admin => %w(),
  :editor => %w(),
  :censor => %w()
}.each_pair { |role, users| users.each { |user| user.has_role!(role) } }

## CATEGORIES

%w(echonomyjam echocracy echo).each { |name| Tag.create(:value => name) }

