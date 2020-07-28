require 'open-uri'
require 'json'

class GamesController < ApplicationController
  VOWELS = %w(A E I O U Y)

  def new
    @letters = Array.new(5) { VOWELS.sample }
    @letters += Array.new(5) { (('A'..'Z').to_a - VOWELS).sample }
    @letters.shuffle!
  end

  def score
    @word = (params[:word] || "").upcase
    @letters = params[:letters].split
    @included = grid_check(@word, @letters)
    @english_word = english_word?(@word)
  end

  private

  def grid_check(attempt, grid)
    attempt.chars.all? { |letter| attempt.count(letter) <= grid.count(letter) }
  end

  def english_word?(attempt)
    serialized_dictionary = open("https://wagon-dictionary.herokuapp.com/#{attempt}").read
    dictionary = JSON.parse(serialized_dictionary)
    dictionary['found']
  end

  def compute_score(attempt, time_taken)
    time_taken > 60 ? 0 : attempt.length * (1.0 - time_taken / 60)
  end

  def score_and_message(attempt, grid, time)
    if grid_check(grid, attempt.upcase)
      if english_word?(attempt)
        score = compute_score(attempt, time)
        [score, "well done"]
      else
        [0, "not an english word"]
      end
    else
      [0, "not in the grid"]
    end
  end

  def run_game(attempt, grid, start_time, end_time)
    result = { time: end_time - start_time }

    score_and_message = score_and_message(attempt, grid, result[:time])
    result[:score] = score_and_message.first
    result[:message] = score_and_message.last

    result
  end
end
