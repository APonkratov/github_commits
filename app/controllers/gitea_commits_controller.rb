class GiteaCommitsController < ApplicationController
  
  unloadable
  
  skip_before_filter :check_if_login_required
  skip_before_filter :verify_authenticity_token

  REDMINE_JOURNALIZED_TYPE = "Issue"
  REDMINE_ISSUE_NUMBER_PREFIX = "#"

  def create_comment
    resp_json = nil
    if params[:commits].present?
      
      repository_name = params[:repository][:name]
      branch = params[:ref].split("/").last
      
      params[:commits].each do |last_commit|
        message = last_commit[:message]

        if message.present? && is_commit_to_be_tracked?(last_commit)         
          issue_id = message.partition(REDMINE_ISSUE_NUMBER_PREFIX).last.split(" ").first.to_i
          issue = Issue.find_by(id: issue_id)
        end

        if last_commit.present? && issue.present?

          email = EmailAddress.find_by(address: last_commit[:author][:email])
          user = email.present? ? email.user : User.where(admin: true).first
          
          author = last_commit[:author][:name]
          
          notes = t('commit.message', author: author, 
                                      branch: branch, 
                                      message: message, 
                                      commit_id: last_commit[:id],
                                      commit_url: last_commit[:url])
          
          issue.journals.create(journalized_id: issue_id, 
                                journalized_type: REDMINE_JOURNALIZED_TYPE, 
                                user: user, 
                                notes: notes
                               )
          resp_json = {success: true}
        else
          resp_json = {success: false, error: t('lables.no_issue_found') }
        end
      end
      
    else
      resp_json = {success: false, error: t('lables.no_commit_data_found') }
    end

    respond_to do |format|
      format.json { render json: resp_json, status: :ok }
    end

  end

  private

  def is_commit_to_be_tracked?(commit_obj)
    commit_obj[:message].include?(REDMINE_ISSUE_NUMBER_PREFIX) #Does it include the redmine issue prefix string pattern?
  end
end
