module Mammoth::Api::V1
	class WaitListsController < Api::BaseController
		skip_before_action :require_authenticated_user!

    def register_end_user_waitlist
      if wait_lists_params[:email].present?
        @user_wait_list= Mammoth::WaitList.create!(
          role: "end-user",
          email: wait_lists_params[:email],
          invitation_code: generate_verify_code()
        ) 
        render json: {message: 'Successfully registered.'}  
      end
    end

    def register_moderator_waitlist
      if wait_lists_params[:email].present?
        @user_wait_list= Mammoth::WaitList.create!(
          role: "moderator",
          email: wait_lists_params[:email],
          invitation_code: generate_verify_code(),
          description: wait_lists_params[:description]
        ) 
        render json: {message: 'Successfully registered.'}  
      end
    end

    def register_contributor_waitlist
      if wait_lists_params[:email].present? && wait_lists_params[:role_id].present?
        @contributor_role = Mammoth::ContributorRole.find_by(slug: wait_lists_params[:role_id])
        @user_wait_list= Mammoth::WaitList.create!(
          role: "contributor",
          email: wait_lists_params[:email],
          invitation_code: generate_verify_code(),
          description: wait_lists_params[:description],
          contributor_role_id: @contributor_role.id
        ) 
        render json: {message: 'Successfully registered.'}  
      end
    end

    def get_contributor_roles
      contributor_roles = Mammoth::ContributorRole.all
      render json: contributor_roles 
    end

    private
    def wait_lists_params
      params.require(:wait_lists).permit(:email, :invitation_code, :role, 
                :role_id, :description, :is_invitation_code_used)
    end

    def generate_verify_code
      number_array = (1..9).to_a
      verify_code = (0...4).collect { number_array[Kernel.rand(number_array.length)] }.join
    end

  end
end