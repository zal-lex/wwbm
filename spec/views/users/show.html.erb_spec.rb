require 'rails_helper'

# Тест на шаблон users/show.html.erb

RSpec.describe 'users/show', type: :view do
  # Проверка в случае не залогиненого пользователя
  context 'Anonymous user' do
    # Создадим пользователя и пару игр для него
    before(:example) do
      user = assign(:user, FactoryBot.create(:user, name: 'James Bond'))
      stub_template 'users/_game.html.erb' => 'User game goes here'
      # assign(:games, [
      #   FactoryBot.build_stubbed(:game, id: 15, created_at: Time.parse('2020.04.09, 13:00'), current_level: 10, prize: 1000),
      #   FactoryBot.build_stubbed(:game, id: 10, created_at: Time.parse('2020.04.03, 16:00'), current_level: 11, prize: 32000)
      # ])
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

    # it 'renders player balances' do
    #   expect(rendered).to match /1 000.*32 000/m
    # end
  end

  # Проверяем случай, когда пользователь залогинился
  context 'Authorized user' do
    # Создадим пользователя и пару игр для него, авторизуем пользователя
    before(:example) do
      user = assign(:user, FactoryBot.create(:user, name: 'James Bond'))
      stub_template 'users/_game.html.erb' => 'User game goes here'
      # assign(:games, [
      #   FactoryBot.build_stubbed(:game, id: 15, created_at: Time.parse('2020.04.09, 13:00'), current_level: 10, prize: 1000),
      #   FactoryBot.build_stubbed(:game, id: 10, created_at: Time.parse('2020.04.03, 16:00'), current_level: 11, prize: 32000)
      # ])
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

    # it 'renders player balances' do
    #   expect(rendered).to match /1 000.*32 000/m
    # end
  end
end
