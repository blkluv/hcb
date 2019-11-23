require 'sidekiq/web'
require 'admin_constraint'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq', constraints: AdminConstraint.new
  get '/sidekiq', to: 'users#auth' # fallback if adminconstraint fails, meaning user is not signed in

  root to: 'static_pages#index'
  get 'stats', to: 'static_pages#stats'

  get 'apply', to: 'applications#apply'
  post 'submit', to: 'applications#submit'

  resources :users, only: [:edit, :update] do
    collection do
      get 'auth', to: 'users#auth'
      post 'login_code', to: 'users#login_code'
      post 'exchange_login_code', to: 'users#exchange_login_code'
      delete 'logout', to: 'users#logout'

      # sometimes users refresh the login code page and get 404'd
      get 'exchange_login_code', to: redirect('/users/auth', status: 301)
      get 'login_code', to: redirect('/users/auth', status: 301)
    end
    post 'delete_profile_picture', to: 'users#delete_profile_picture'
  end

  resources :organizer_position_invites, only: [:index, :show], path: 'invites' do
    post 'accept'
    post 'reject'
    post 'cancel'
  end

  resources :organizer_positions, only: [:destroy], as: 'organizers' do
    resources :organizer_position_deletion_requests, only: [:new], as: 'remove'
  end

  resources :organizer_position_deletion_requests, only: [:index, :show, :create] do
    post 'close'
    post 'open'

    resources :comments
  end

  resources :g_suite_applications, except: [:new, :create, :edit, :update] do
    post 'accept'
    post 'reject'

    resources :comments
  end

  resources :g_suite_accounts, only: [:index, :create, :update, :edit], path: 'g_suite_accounts' do
    get 'verify', to: 'g_suite_account#verify'
    post 'reject'
  end

  resources :g_suites, except: [:new, :create, :edit, :update] do
    resources :g_suite_accounts, only: [:create]

    resources :comments
  end

  resources :sponsors

  resources :invoices, only: [:show] do
    collection do
      get '', to: 'invoices#all_index', as: :all
    end
    get 'manual_payment'
    post 'manually_mark_as_paid'
    post 'archive'
    post 'unarchive'
    resources :comments
  end

  resources :cards

  resources :checks, only: [:show, :index, :edit, :update] do
    collection do
      get 'export'
    end

    get 'start_approval'
    post 'approve'
    get 'start_void'
    post 'void'
    get 'refund', to: 'checks#refund_get'
    post 'refund', to: 'checks#refund'
  end

  resources :ach_transfers, only: [:show, :index] do
    get 'start_approval'
    post 'approve'
  end

  resources :documents, except: [:index] do
    get 'download'
  end

  resources :bank_accounts, only: [:new, :create, :update, :show, :index] do
    get 'reauthenticate'
  end

  resources :transactions, only: [:index, :show, :edit, :update] do
    collection do
      get 'export'
    end
    resources :comments
  end

  resources :fee_reimbursements, only: [:index, :show, :edit, :update] do
    post 'mark_as_processed'
    resources :comments
  end

  get 'pending_fees', to: 'static_pages#pending_fees'
  get 'branding', to: 'static_pages#branding'

  resources :card_requests, path: 'card_requests' do
    post 'reject'
    post 'cancel'

    resources :comments
  end

  resources :load_card_requests, except: [:new] do
    post 'accept'
    post 'reject'
    post 'cancel'
    resources :comments
  end

  resources :emburse_transactions, only: [:index, :edit, :update]

  post 'export/finances', to: 'exports#financial_export'

  get 'pending_fees', to: 'static_pages#pending_fees'
  get 'negative_events', to: 'static_pages#negative_events'

  post '/events' => 'events#create'
  get '/events' => 'events#index'
  get '/event_by_airtable_id/:airtable_id' => 'events#by_airtable_id'
  resources :events, path: '/' do
    get 'team', to: 'events#team', as: :team
    get 'g_suite', to: 'events#g_suite_overview', as: :g_suite_overview
    get 'cards', to: 'events#card_overview', as: :cards_overview
    get 'transfers', to: 'events#transfers', as: :transfers
    get 'promotions', to: 'events#promotions', as: :promotions
    resources :checks, only: [:new, :create]
    resources :ach_transfers, only: [:new, :create]
    resources :organizer_position_invites,
              only: [:new, :create],
              path: 'invites'
    resources :g_suites, only: [:new, :create, :edit, :update]
    resources :g_suite_applications, only: [:new, :create, :edit, :update]
    resources :load_card_requests, only: [:new]
    resources :documents, only: [:index]
    get 'fiscal_sponsorship_letter', to: 'documents#fiscal_sponsorship_letter'
    resources :invoices, only: [:new, :create, :index]
  end

  # rewrite old event urls to the new ones not prefixed by /events/
  get '/events/*path', to: redirect('/%{path}', status: 302)

  # Beware: Routes after "resources :events" might be overwritten by a
  # similarly named event
end
