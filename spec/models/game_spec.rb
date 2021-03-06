# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryBot.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(# проверка: Game.count изменился на 1 (создали в базе 1 игру)
        change(GameQuestion, :count).by(15).and(# GameQuestion.count +15
          change(Question, :count).by(0) # Game.count не должен измениться
        )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # тесты на основную игровую логику
  context 'game mechanics' do
    # правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)
      # ранее текущий вопрос стал предыдущим
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)
      # игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take_money! finishes the game' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      # забираем деньги
      game_w_questions.take_money!

      prize = game_w_questions.prize
      expect(prize).to be > 0

      # игра завершилась
      expect(game_w_questions.status).to eq(:money)
      expect(game_w_questions.finished?).to be true
      expect(user.balance).to eq prize
    end
  end

  # группа тестов на проверку статуса игры
  context '.status' do
    # перед каждым тестом "завершаем игру"
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  # группа тестов на проверку метода, возвращающего предыдущий уровень
  context '.previous_level' do
    it 'return `-1` at start of the game' do
      expect(game_w_questions.previous_level).to eq(-1)
    end

    it 'return `0` when player made correct answer at first question' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.previous_level).to eq(0)
    end
  end

  # тест на проверку текущего игрового вопроса
  context '.current_game_question' do
    it 'return exactily current question (0 level)' do
      question = game_w_questions.game_questions.detect { |q| q.question.level == 0 }
      expect(game_w_questions.current_game_question).to eq(question)
    end
  end

  # группа тестов на проверку метода ответа на вопрос
  describe '.answer_current_question!(letter)' do
    let(:q) { game_w_questions.current_game_question }
    let(:correct_answer_key) { q.correct_answer_key }
    let(:incorrect_answer_key) { (%w[a b c d] - [correct_answer_key]).pop }
    subject(:correct_answered) { game_w_questions.answer_current_question!(correct_answer_key) }
    subject(:incorrect_answered) { game_w_questions.answer_current_question!(incorrect_answer_key) }

    # когда дан верный ответ и до истечения времени
    context 'correct answer in TIME_LIMIT' do
      it 'return true' do
        expect(correct_answered).to be true
      end

      it 'raise up current level' do
        level = game_w_questions.current_level
        game_w_questions.answer_current_question!(correct_answer_key)
        expect(game_w_questions.current_level).to eq(level + 1)
      end

      it 'rewrite updated_at' do
        updated_timestamp = game_w_questions.updated_at
        game_w_questions.answer_current_question!(correct_answer_key)
        expect(game_w_questions.updated_at).to be
      end

      # когда дан ответ на последний вопрос
      context 'when it was the last question' do
        before(:example) do
          game_w_questions.current_level = 14
          game_w_questions.answer_current_question!(correct_answer_key)
        end

        it 'change game status to :won' do
          expect(game_w_questions.status).to eq(:won)
        end

        it 'set up prize to 1_000_000' do
          expect(game_w_questions.prize).to eq(1000000)
        end

        it 'game was finished' do
          game_w_questions.answer_current_question!(correct_answer_key)
          expect(game_w_questions.finished?).to be true
        end
      end
    end

    # когда дан верный ответ на 6й вопрос после завершения лимита времини
    context 'correct answer at 6th question when TIME_LIMIT is over' do
      before(:example) do
        game_w_questions.current_level = 5
        game_w_questions.created_at = 1.hour.ago
      end

      it 'return false' do
        expect(correct_answered).to be false
      end

      it 'change game status to :timeout' do
        game_w_questions.answer_current_question!(correct_answer_key)
        expect(game_w_questions.status).to eq(:timeout)
      end

      it 'set up prize to 1000' do
        game_w_questions.answer_current_question!(correct_answer_key)
        expect(game_w_questions.prize).to eq(1000)
      end

      it 'game was finished' do
        game_w_questions.answer_current_question!(correct_answer_key)
        expect(game_w_questions.finished?).to be true
      end
    end

    # когда дан не верный ответ на 6й вопрос
    context 'wrong answer' do
      before(:example) do
        game_w_questions.current_level = 5
      end

      it 'return false' do
        expect(incorrect_answered).to be false
      end

      it 'change game status to :fail' do
        game_w_questions.answer_current_question!(incorrect_answer_key)
        expect(game_w_questions.status).to eq(:fail)
      end

      it 'set up prize to 1000' do
        game_w_questions.answer_current_question!(incorrect_answer_key)
        expect(game_w_questions.prize).to eq(1000)
      end

      it 'game was finished' do
        game_w_questions.answer_current_question!(incorrect_answer_key)
        expect(game_w_questions.finished?).to be true
      end
    end

    # игра была завершена ранее
    context 'game was finished earler' do
      it 'return false' do
        game_w_questions.finished_at = 1.hour.ago
        expect(incorrect_answered).to be false
      end
    end
  end
end
