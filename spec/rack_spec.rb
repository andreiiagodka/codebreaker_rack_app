# frozen_string_literal: true
require 'pry'
RSpec.describe CodebreakerRoute do
  def app
    Rack::Builder.parse_file('./config.ru').first
  end

  let(:valid_player_name) { 'a' * Codebreaker::Player::NAME_LENGTH_RANGE.min }
  let(:secret_code) { Array.new(Codebreaker::Game::SECRET_CODE_LENGTH, 1) }
  let(:valid_guess_code) { '2' * Codebreaker::Game::SECRET_CODE_LENGTH }

  let(:difficulty_double) { instance_double('Difficulty', level:Codebreaker::Difficulty::DIFFICULTIES[:easy]) }
  let(:player) { Codebreaker::Player.new(valid_player_name) }
  let(:difficulty) { Codebreaker::Difficulty.new(Codebreaker::Difficulty::DIFFICULTIES[:easy][:level]) }
  let(:game) { Codebreaker::Game.new(difficulty.level) }

  describe 'access to inactive mode pages' do
    context 'index page' do
      let(:response) { get CodebreakerRoute::ROUTES[:index] }

      it { expect(response).to be_ok }
      it { expect(response.body).to include I18n.t('index_page.player_name') }
    end

    context 'rules page' do
      let(:response) { get CodebreakerRoute::ROUTES[:rules] }

      it { expect(response).to be_ok }
      it { expect(response.body).to include I18n.t('rules_page.title') }
    end

    context 'statistics page' do
      let(:response) { get CodebreakerRoute::ROUTES[:statistics] }

      it { expect(response).to be_ok }
      it { expect(response.body).to include I18n.t('statistics_page.top') }
    end
  end

  describe 'player registration' do
    context 'valid data is given and it redirects to game page' do
      let(:response) do
        post CodebreakerRoute::ROUTES[:registration], player_name: valid_player_name,
                                                      level: difficulty_double.level[:level]
      end

      before do
        response
        follow_redirect!
      end

      it { expect(last_request.session[:player].name).to eq valid_player_name }
      it { expect(last_request.session[:game].difficulty).to eq difficulty_double.level[:level] }
      it { expect(response).to be_redirect }
      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include I18n.t('game_page.greeting', name: valid_player_name) }
    end

    context 'invalid data is given and it redirects to index page' do
      let(:invalid_player_name) { 'a' * (Codebreaker::Player::NAME_LENGTH_RANGE.min - 1) }
      let(:invalid_level) { difficulty_double.level[:level].succ }
      let(:response) do
        post CodebreakerRoute::ROUTES[:registration], player_name: invalid_player_name,
                                                      level: invalid_level
      end

      before do
        response
        follow_redirect!
      end

      it { expect(last_request.session[:game]).to eq nil }
      it { expect(response).to be_redirect }
      it { expect(last_response).to be_ok }
      it {
        expect(last_response.body).to include I18n.t('error.player_name_length',
                                                     min_length: Codebreaker::Player::NAME_LENGTH_RANGE.min,
                                                     max_length: Codebreaker::Player::NAME_LENGTH_RANGE.max)
      }
      it { expect(last_response.body).to include I18n.t('error.unexpected_difficulty') }
    end
  end

  describe 'player tries to access routes which are not available during inactive mode' do
    context 'it redirects to index page' do
      CodebreakerRoute::ROUTES.values.last(5).each do |route|
        before { get route }

        it { expect(last_response).to be_redirect }
        it do
          follow_redirect!
          expect(last_response).to be_ok
        end
        it do
          follow_redirect!
          expect(last_response.body).to include I18n.t('index_page.player_name')
        end
      end
    end
  end

  describe 'player tries to access routes which are available during active mode' do
    context 'it redirects to game page' do
      CodebreakerRoute::ROUTES.values.first(6).each do |route|
        before do
          env 'rack.session', player: player, difficulty: difficulty, game: game
          get route
        end

        it { expect(last_response).to be_redirect }
        it do
          follow_redirect!
          expect(last_response).to be_ok
        end
        it do
          follow_redirect!
          expect(last_response.body).to include I18n.t('game_page.greeting', name: valid_player_name)
        end
      end
    end
  end

  describe 'player uses hint and it redirects to game page' do
    let(:response) { get CodebreakerRoute::ROUTES[:hint] }

    before do
      env 'rack.session', player: player, difficulty: difficulty, game: game
      response
      follow_redirect!
    end

    it { expect(response).to be_redirect }
    it { expect(last_response).to be_ok }
    it { expect(last_request.session[:game].use_hint).not_to eq nil }
    it { expect(last_request.session[:hints]).not_to be_empty }
    it { expect(last_response.body).to include last_request.session[:hints].join }
    it { expect(last_response.body).to include I18n.t('game_page.greeting', name: valid_player_name) }
  end

  describe 'player makes guess and it redirects to game page' do
    before { env 'rack.session', player: player, difficulty: difficulty, game: game }

    context 'valid guess code is given' do
      let(:response) { post CodebreakerRoute::ROUTES[:guess], guess_code: valid_guess_code }

      before do
        response
        game.instance_variable_set(:@secret_code, secret_code)
        follow_redirect!
      end

      it { expect(response).to be_redirect }
      it { expect(last_response).to be_ok }
      it { expect(last_request.session[:marked_guess]).not_to eq nil }
      it { expect(last_response.body).to include I18n.t('game_page.greeting', name: valid_player_name) }
    end

    context 'invalid guess code is given' do
      let(:invalid_digit) { Codebreaker::Game::ELEMENT_VALUE_RANGE.max + 1 }
      let(:invalid_guess_code) { invalid_digit.to_s + valid_guess_code }
      let(:response) { post CodebreakerRoute::ROUTES[:guess], guess_code: invalid_guess_code }

      before do
        response
        follow_redirect!
      end

      it { expect(response).to be_redirect }
      it { expect(last_response).to be_ok }
      it { expect(last_request.session[:marked_guess]).to eq nil }
      it { expect(last_response.body).to include I18n.t('error.secret_code_length', code_length: Codebreaker::Game::SECRET_CODE_LENGTH) }
      it {
        expect(last_response.body).to include I18n.t('error.secret_code_digits_range',
                                                      min_value: Codebreaker::Guess::ELEMENT_VALUE_RANGE.min,
                                                      max_value: Codebreaker::Guess::ELEMENT_VALUE_RANGE.max)
        }
    end
  end

  describe 'player loses and is redirected to lose page' do
    let(:response) { post CodebreakerRoute::ROUTES[:guess], guess_code: valid_guess_code }

    before do
      env 'rack.session', player: player, difficulty: difficulty, game: game
      game.instance_variable_set(:@secret_code, secret_code)
      game.instance_variable_set(:@used_attempts, game.total_attempts)
      response
      follow_redirect!
    end

    it { expect(response).to be_redirect }
    it { expect(last_response).to be_ok }
    it { expect(last_request.session[:game]).to eq nil }
    it { expect(last_response.body).to include I18n.t('lose_page.lose_msg', name: valid_player_name) }
  end

  describe 'player wins and is redirected to win page' do
    let(:correct_guess_code) { secret_code.join }
    let(:test_db_path) { 'spec/fixtures/test_database.yml' }
    let(:response) { post CodebreakerRoute::ROUTES[:guess], guess_code: correct_guess_code }

    before do
      env 'rack.session', player: player, difficulty: difficulty, game: game
      game.instance_variable_set(:@secret_code, secret_code)
      File.new(test_db_path, 'w+')
      stub_const('Codebreaker::Statistic::STATISTIC_YML', test_db_path)
      response
      follow_redirect!
    end

    after { File.delete(test_db_path) }

    it { expect(response).to be_redirect }
    it { expect(last_response).to be_ok }
    it { expect(Codebreaker::Statistic.new.load_statistics.empty?).to eq false }
    it { expect(last_request.session[:game]).to eq nil }
    it { expect(last_response.body).to include I18n.t('win_page.win_msg', name: valid_player_name) }
  end
end
