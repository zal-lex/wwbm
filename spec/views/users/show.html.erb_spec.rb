require 'rails_helper'

# Тест на шаблон users/show.html.erb

RSpec.describe 'users/show', type: :view do
  # Проверка в случае не залогиненого пользователя
  context 'Anonymous user' do
    # Создадим пользователя и пару игр для него
    before(:example) do
      user = assign(:user, FactoryBot.create(:user, name: 'James Bond'))
      stub_template 'users/_game.html.erb' => 'User game goes here'
      assign(:games, [double(:game)])
      render
    end

    # Проверяем, что у анонима не выводится ссылка на смену логина и пароля
    it 'anonim have no link to change name or password' do
      expect(rendered).not_to have_content 'Сменить имя и пароль'
    end

    # Проверяем, что шаблон выводит имя игрока
    it 'player name' do
      expect(rendered).to have_content 'James Bond'
    end

    # Проверяем, что шаблон выводит паршиал
    it 'renders partial' do
      expect(rendered).to have_content 'User game goes here'
    end
  end

  # Проверяем случай, когда пользователь залогинился
  context 'Authorized user' do
    # Создадим пользователя и пару игр для него, авторизуем пользователя
    before(:example) do
      user = assign(:user, FactoryBot.create(:user, name: 'James Bond'))
      stub_template 'users/_game.html.erb' => 'User game goes here'
      assign(:games, [double(:game)])
      sign_in user

      render
    end

    # На странице должна появиться ссылка на смену логина и пароля
    it 'authorized user have link to change name or password' do
      expect(rendered).to have_content 'Сменить имя и пароль'
    end

    # Проверяем, что шаблон выводит имя игрока
    it 'player name' do
      expect(rendered).to have_content 'James Bond'
    end

    # Проверяем, что шаблон выводит паршиал
    it 'renders partial' do
      expect(rendered).to have_content 'User game goes here'
    end
  end
end
