Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"

  get "sign_in", to: "sessions#new", as: :new_session
  post "sign_in", to: "sessions#create", as: :session
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  get "sign_up", to: "sign_ups#new", as: :new_sign_up
  post "sign_up", to: "sign_ups#create", as: :sign_up

  get "password/reset", to: "password_resets#new", as: :new_password_reset
  post "password/reset", to: "password_resets#create", as: :password_resets
  get "password/reset/:token", to: "password_resets#edit", as: :edit_password_reset
  patch "password/reset/:token", to: "password_resets#update"

  get "email_confirmations/new", to: "email_confirmations#new", as: :new_email_confirmation
  post "email_confirmations", to: "email_confirmations#create", as: :email_confirmations
  get "email_confirmations/:token", to: "email_confirmations#show", as: :email_confirmation

  get "magic_link", to: "magic_links#new", as: :new_magic_link
  post "magic_link", to: "magic_links#create", as: :magic_links
  get "magic_link/:token", to: "magic_links#show", as: :magic_link

  resource :profile, only: %i[ show update ]
  patch "profile/password", to: "profiles#update_password", as: :profile_password
  delete "profile/sessions/:id", to: "profiles#destroy_session", as: :profile_session
  delete "profile/sessions", to: "profiles#revoke_other_sessions", as: :profile_sessions
end
