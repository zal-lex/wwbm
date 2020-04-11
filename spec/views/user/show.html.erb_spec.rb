require 'rails_helper'

# Тест на шаблон users/show.html.erb

RSpec.describe 'users/show', type: :view do
  # Перед каждым шагом мы пропишем в переменную @user самого пользователя
  # и застабим вывод шаблона для игр
  describe 'renders the players game partial and user name' do
    before(:example) do
      assign(:user, FactoryBot.build_stubbed(:user, name: 'James Bond'))
      # stub_template 'users/_game.html.erb' => 'User game goes here'
      assign(:games, [
        FactoryBot.build_stubbed(:game, id: 15, created_at: Time.parse('2020.04.09, 13:00'), current_level: 10, prize: 1000),
        FactoryBot.build_stubbed(:game, id: 10, created_at: Time.parse('2020.04.03, 16:00'), current_level: 11, prize: 32000)
      ])
    end

    shared_examples 'user template' do
      # Проверяем, что шаблон выводит имя игрока
      it 'player name' do
        render
        expect(rendered).to have_content 'James Bond'
      end

      # Проверяем, что шаблон выводит паршиал
      # it 'renders partial' do
        # expect(rendered).to have_content 'User game goes here'
      # end
      it 'renders player balances' do
        render
        expect(rendered).to match /1 000.*32 000/m
      end
    end

    context 'Anonymous user' do
      it 'anonim have no link to change name or password' do
        render
        expect(rendered).not_to have_content 'Сменить имя и пароль'
      end

      it_behaves_like 'user template'
    end

    context 'Authorized user' do
      it 'authorized user have link to change name or password' do
        user = FactoryBot.build_stubbed(:user, name: 'James Bond')
        sign_in user
        assign(:user, user)
        render
        expect(rendered).to have_content 'Сменить имя и пароль'
      end

      it_behaves_like 'user template'
    end

  end
end
