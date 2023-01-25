module Mammoth::Api::V1
	class WaitListsController < Api::BaseController
    before_action -> { doorkeeper_authorize! :write }
		skip_before_action :require_authenticated_user!

    def verify_waitlist
      if wait_lists_params[:invitation_code].present?
        verified_code = Mammoth::WaitList.find_by(invitation_code: wait_lists_params[:invitation_code])
          if verified_code.invitation_code == wait_lists_params[:invitation_code]
            verified_code.update(is_invitation_code_used: true)
            render json: {message: 'Successfully verified.'} 
          else
            render json: {error: 'Unsuccessfully verified.'} 
        end
         
      end
    end

    def register_end_user_waitlist
      if wait_lists_params[:email].present?
        save_wait_list("end-user",wait_lists_params[:email],nil,nil)
        render json: {message: 'Successfully registered.'}  
      end
    end

    def register_moderator_waitlist
      if wait_lists_params[:email].present?
        save_wait_list("moderator",wait_lists_params[:email],wait_lists_params[:description],nil)
        render json: {message: 'Successfully registered.'}  
      end
    end

    def register_contributor_waitlist
      if wait_lists_params[:email].present? && wait_lists_params[:role_id].present?
        @contributor_role = Mammoth::ContributorRole.find_by(slug: wait_lists_params[:role_id])
        save_wait_list("contributor",wait_lists_params[:email],wait_lists_params[:description],@contributor_role.id)
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

    def save_wait_list(role,email,description,contributor_role_id)
      @user_wait_list= Mammoth::WaitList.create!(
        role: role,
        email: email,
        invitation_code: generate_verify_code(),
        description: description,
        contributor_role_id: contributor_role_id
      ) 
    end

  end
end