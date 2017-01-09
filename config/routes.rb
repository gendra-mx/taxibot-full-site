# Copyright 2015, Google, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Rails.application.routes.draw do

  resources :drivers
  get 'drivers/all'

  get 'login/start'

  get 'pasajeros', to: 'passengers#wellcome'

  get 'ciudades', to: 'cities#all'

  get 'conductores', to: 'drivers#new'

  get 'wellcome/index'

  get 'register/start'

  resources :books
  resources :drivers, only: [:create, :destroy]

  post "/drivers/:id/uploads", to: "drivers#upload"

  # [START login]
  get "/login", to: 'login#start'
  # [END login]

  # [START sessions]
  get "/auth/google_oauth2/callback", to: "sessions#create"

  resource :session, only: [:create, :destroy]
  # [END sessions]

  # [START user_books]
  resources :user_books, only: [:index]
  # [END user_books]

  # [START logout]
  get "/logout", to: "sessions#destroy"
  # [END logout]


  root "wellcome#index"

end
