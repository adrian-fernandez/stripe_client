module ApplicationHelper
  def flash_messages
    render 'shared/flash_messages' unless flash.empty? 
  end
end
