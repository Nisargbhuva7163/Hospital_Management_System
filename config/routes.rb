Rails.application.routes.draw do
  devise_for :users, controllers:
    {
      sessions: "users/sessions",
      registrations: "users/registrations",
      confirmations: "users/confirmations"
    }

  devise_scope :user do
    post "users/send_otp", to: "users/sessions#send_otp", as: :users_send_otp
    post "users/verify_otp", to: "users/sessions#verify_otp", as: :users_verify_otp
    post "/users/resend_otp", to: "users/sessions#resend_otp", as: :users_resend_otp
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  unauthenticated do
    root to: redirect("/users/sign_in"), as: :unauthenticated_root
  end
  # Defines the root path route ("/")
  resources :organizations, only: [ :show, :edit, :update ] do
    member do
      patch :toggle_doctor_status
    end

    resources :booking_windows, only: [ :new, :create, :destroy ]

    resources :appointments do
      collection do
        post :send_otp
        post :verify_otp
      end
      member do
        get :preview
        patch :complete
        patch :skip
      end
    end
  end
end
