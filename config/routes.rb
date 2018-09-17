Rails.application.routes.draw do
  get 'new_action', to: 'foreman_kubevirt/hosts#new_action'
end
