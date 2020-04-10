# Как и в любом тесте, подключаем помощник rspec-rails
require 'rails_helper'

# Начинаем описывать функционал, связанный с созданием игры
RSpec.feature 'USER opens aliens profile', type: :feature do
  # Чтобы посмотреть профиль пользователя, нам надо
  # создать пользователя
  let(:user) { FactoryBot.create :user }

  # создадим пару игр
  let!(:games) { [
    FactoryBot.create(:game, id: 1, user_id: user.id, created_at: Time.parse('2020.04.09, 13:00'), current_level: 10, prize: 1000),
    FactoryBot.create(:game, id: 11, user_id: user.id, created_at: Time.parse('2020.04.07, 11:00'), current_level: 11, prize: 32000)
  ] }

  # Сценарий успешного создания игры
  scenario 'successfully' do
    # Заходим на страницу пользователя
    visit "/users/#{user.id}"
    # save_and_open_page

    # Ожидаем, что на экране nickname пользователя
    expect(page).to have_content "#{user.name}"

    # Ожидаем, что на экране две игры с определёнными датами создания и выигрышами
    expect(page).to have_content '09 апр., 13:00'
    expect(page).to have_content '07 апр., 11:00'
    expect(page).to have_content '1 000 ₽'
    expect(page).to have_content '32 000 ₽'

    # Ожидаем, что на экране нет ссылки на смену имени пользователя и пароля
    expect(page).not_to have_content 'Сменить имя и пароль'

  end
end
