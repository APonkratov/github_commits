# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
post 'gitea_commits/create_comment.json', to: 'github_commits#create_comment'
