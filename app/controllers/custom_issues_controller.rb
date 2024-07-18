class CustomIssuesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :update_collapsed_ids

  def update_collapsed_ids
    @issue = Issue.find(params[:id])

    json_data = JSON.parse(request.body.read)
    if @issue.update(collapsed_ids: json_data["collapsed_ids"])
      render json: { message: 'Collapsed IDs updated successfully' }, status: :ok
    else
      render json: { error: 'Failed to update collapsed IDs' }, status: :unprocessable_entity
    end

  end
end
