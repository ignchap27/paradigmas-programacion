%% ============================================================================
%% MastermindGame Class
%% Main game controller that manages the overall game flow
%% ============================================================================
%% Color enumeration - valid colors in the game
%% Type: Color :: red | blue | green | yellow | orange | purple
%% ============================================================================
declare MastermindGame CodeBreaker CodeMaker
declare Colors Seed RandomIndex Occurrences CountBlacks CountCommon Repeat ValidCode AllCodes

Colors = [red blue green yellow orange purple]

Seed = {NewCell 20250913}

fun {RandomIndex N}
   Next = (@Seed * 1103515245 + 12345) mod 2147483647
in
   Seed := Next
   Next mod N + 1
end

fun {Occurrences Color L}
   {Length {Filter L fun {$ X} X == Color end}}
end

fun {CountBlacks Code Guess}
   {FoldL {List.zip Code Guess fun {$ A B} if A == B then 1 else 0 end end}
    Number.'+' 0}
end

fun {CountCommon Code Guess}
   {FoldL {Map Colors fun {$ C} {Min {Occurrences C Code} {Occurrences C Guess}} end}
    Number.'+' 0}
end

fun {Repeat X N}
   if N =< 0 then nil else X|{Repeat X N-1} end
end

fun {ValidCode Code}
   {Length Code} == 4 andthen {List.all Code fun {$ C} {Member C Colors} end}
end

fun {AllCodes}
   for A in Colors collect:Add do
      for B in Colors do
         for C in Colors do
            for D in Colors do {Add [A B C D]} end
         end
      end
   end
end

class MastermindGame
   attr codemaker codebreaker currentRound maxRounds gameStatus

   meth init(CodemakerObj CodebreakerObj)
      %% Initialize a new Mastermind game
      %% Input: CodemakerObj :: CodeMaker - Object implementing codemaker behavior
      %%        CodebreakerObj :: CodeBreaker - Object implementing codebreaker behavior
      %% Side effects: Initializes game state, sets maxRounds to 12
      %% Postcondition: Game ready to start, gameStatus = 'ready'
      codemaker := CodemakerObj
      codebreaker := CodebreakerObj
      currentRound := 0
      maxRounds := 12
      gameStatus := ready
   end

   meth startGame(?Result)
      %% Starts a new game session
      %% Input: None
      %% Output: Result :: Bool - true if game started successfully, false otherwise
      %% Side effects: Resets game state, generates new secret code
      %% Precondition: Game must be in 'ready' or 'finished' state
      %% Postcondition: Game in 'playing' state, currentRound = 1
      if @gameStatus == playing then
         Result = false
      else
         {@codemaker generateSecretCode(_)}
         {@codebreaker resetHistory()}
         currentRound := 1
         gameStatus := playing
         Result = true
      end
   end

   meth playRound(?Result)
      %% Executes one round of the game (guess + feedback)
      %% Input: None
      %% Output: Result :: GameRoundResult - Record containing round results
      %%         GameRoundResult = result(
      %%            guess: [Color]           % The guess made this round
      %%            feedback: [FeedbackClue] % Black and white Clues received
      %%            roundNumber: Int         % Current round number
      %%            gameWon: Bool            % Whether game was won this round
      %%            gameOver: Bool           % Whether game is over
      %%         )
      %% Precondition: Game must be in 'playing' state
      %% Side effects: Increments currentRound, may change gameStatus
      if @gameStatus \= playing then
         Result = result(guess: nil feedback: nil roundNumber: @currentRound
                         gameWon: false gameOver: true)
      else
         local Guess Feedback Won Over in
            {@codebreaker nextGuess(Guess)}
            {@codebreaker makeGuess(Guess _)}
            {@codemaker evaluateGuess(Guess Feedback)}
            {@codebreaker receiveFeedback(Guess Feedback)}
            Won = Feedback.isCorrect
            Over = Won orelse (@currentRound >= @maxRounds)
            Result = result(guess: Guess
                            feedback: Feedback.'ClueList'
                            roundNumber: @currentRound
                            gameWon: Won
                            gameOver: Over)
            if Won then gameStatus := won
            elseif Over then gameStatus := lost
            else currentRound := @currentRound + 1
            end
         end
      end
   end

   meth getGameStatus(?Result)
      %% Returns current game status
      %% Input: None
      %% Output: Result :: GameStatus - Current status of the game
      %%         GameStatus :: 'ready' | 'playing' | 'won' | 'lost' | 'finished'
      Result = @gameStatus
   end

   meth getCurrentRound(?Result)
      %% Returns current round number
      %% Input: None
      %% Output: Result :: Int - Current round number (1-12)
      Result = @currentRound
   end

   meth getRemainingRounds(?Result)
      %% Returns number of rounds left
      %% Input: None
      %% Output: Result :: Int - Number of rounds remaining (0-11)
      Result = @maxRounds - @currentRound
   end

end

%% ============================================================================
%% CodeMaker Class
%% Handles secret code generation and feedback calculation
%% ============================================================================
class CodeMaker
   attr secretCode availableColors

   meth init()
      %% Initialize codemaker with available colors
      %% Input: None
      %% Side effects: Sets availableColors to [red blue green yellow orange purple]
      %% Postcondition: Ready to generate secret codes
      availableColors := Colors
      secretCode := nil
   end

   meth generateSecretCode(?Result)
      %% Generates a new random secret code
      %% Input: None
      %% Output: Result :: Bool - true if code generated successfully
      %% Side effects: Sets new secretCode (4 colors, repetitions allowed)
      %% Postcondition: secretCode contains exactly 4 valid colors
      %% Note: Uses random selection, colors may repeat
      secretCode := {Map [1 2 3 4]
                     fun {$ _}
                        {Nth @availableColors {RandomIndex {Length @availableColors}}}
                     end}
      Result = true
   end

   meth setSecretCode(Code ?Result)
      %% Sets a specific secret code
      %% Input: Code :: [Color] - List of exactly 4 valid colors
      %% Output: Result :: Bool - true if code was set successfully
      %% Validation: Code must have exactly 4 elements, all valid colors
      {self isValidCode(Code Result)}
      if Result then secretCode := Code end
   end

   meth evaluateGuess(Guess ?Result)
      %% Evaluates a guess against the secret code
      %% Input: Guess :: [Color] - List of exactly 4 colors representing the guess
      %% Output: Result :: FeedbackResult - Detailed feedback for the guess
      %%         FeedbackResult = feedback(
      %%            blackClues: Int            % Number of correct color & position
      %%            whiteClues: Int            % Number of correct color, wrong position
      %%            totalCorrect: Int          % blackClues + whiteClues
      %%            isCorrect: Bool            % true if guess matches secret code exactly
      %%            ClueList: [FeedbackClue]   % List of individual Clue results
      %%         )
      %%         FeedbackClue :: black | white | none
      local Black White in
         Black = {CountBlacks @secretCode Guess}
         White = {CountCommon @secretCode Guess} - Black
         Result = feedback(blackClues: Black
                           whiteClues: White
                           totalCorrect: Black + White
                           isCorrect: Black == 4
                           'ClueList': {Append {Repeat black Black}
                                        {Append {Repeat white White}
                                         {Repeat none 4 - Black - White}}})
      end
   end

   meth getSecretCode(?Result)
      %% Returns the current secret code (for testing/debugging)
      %% Input: None
      %% Output: Result :: [Color] | nil - Secret code or nil if not set
      %% Note: Should only be used for testing, breaks game in normal play
      Result = @secretCode
   end

   meth getAvailableColors(?Result)
      %% Returns list of colors that can be used in codes
      %% Input: None
      %% Output: Result :: [Color] - List of available colors for the game
      Result = @availableColors
   end

   meth isValidCode(Code ?Result)
      %% Validates if a code follows game rules
      %% Input: Code :: [Color] - Code to validate
      %% Output: Result :: Bool - true if code is valid for this game
      %% Validation: Exactly 4 colors, all from available color set
      Result = {ValidCode Code}
   end
end

%% ============================================================================
%% CodeBreaker Class
%% Handles guess generation and strategy for breaking codes
%% ============================================================================
declare class CodeBreaker
   attr guessHistory feedbackHistory availableColors

   meth init()
      %% Initialize codebreaker
      %% Postcondition: Ready to make guesses
      guessHistory := nil
      feedbackHistory := nil
      availableColors := Colors
   end

   meth makeGuess(SuggestedGuess ?Result)
      %% Makes a specific guess (overrides strategy)
      %% Input: SuggestedGuess :: [Color] - Specific guess to make
      %% Output: Result :: Bool - true if guess was accepted and recorded
      %% Note: If SuggestedGuess is invalid, return false
      %% Side effects: Records guess in history
      if {ValidCode SuggestedGuess} then
         guessHistory := {Append @guessHistory [SuggestedGuess]}
         Result = true
      else
         Result = false
      end
   end

   meth receiveFeedback(Guess Feedback)
      %% Receives and processes feedback for a guess
      %% Input: Guess :: [Color] - The guess that was evaluated
      %%        Feedback :: FeedbackResult - Feedback received from codemaker
      %% Side effects: Updates internal state, refines strategy if applicable
      %% Note: Smart strategies use this to eliminate future possibilities
      feedbackHistory := {Append @feedbackHistory [Feedback]}
   end

   meth getGuessHistory(?Result)
      %% Returns all guesses made so far
      %% Input: None
      %% Output: Result :: [GuessRecord] - History of all guesses
      %%         GuessRecord = record(
      %%            guess: [Color]
      %%            feedback: FeedbackResult
      %%            roundNumber: Int
      %%         )
      Result = {self buildGuessRecords(@guessHistory @feedbackHistory 1 $)}
   end

   meth getFeedbackHistory(?Result)
      %% Returns feedback for all guesses made so far
      %% Input: None
      %% Output: Result :: [FeedbackRecord] - History of all feedback
      %%         FeedbackRecord = record(
      %%            feedback: FeedbackResult
      %%            roundNumber: Int
      %%         )
      Result = {self buildFeedbackRecords(@feedbackHistory 1 $)}
   end

   meth resetHistory()
      %% Clears guess and feedback history (for new game)
      %% Input: None
      %% Output: None (void)
      %% Side effects: Clears guessHistory and feedbackHistory
      guessHistory := nil
      feedbackHistory := nil
   end

   meth getRemainingPossibilities(?Result)
      %% Returns estimated number of remaining possible codes (smart strategy only)
      %% Input: None
      %% Output: Result :: Int | nil - Number of possibilities or nil if not applicable
      %% Note: Only meaningful for 'smart' strategy, returns nil for others
      Result = {Length {self consistentCodes($)}}
   end

   meth nextGuess(?Result)
      case {self consistentCodes($)}
      of nil then Result = [red red red red]
      [] Code|_ then Result = Code
      end
   end

   meth consistentCodes(?Result)
      Result = {Filter {AllCodes} fun {$ Code} {self isConsistent(Code $)} end}
   end

   meth isConsistent(Code ?Result)
      Result = {List.all {List.zip @guessHistory @feedbackHistory
                          fun {$ Guess Feedback}
                             {CountBlacks Code Guess} == Feedback.blackClues
                             andthen
                             {CountCommon Code Guess} == Feedback.totalCorrect
                          end}
                fun {$ X} X end}
   end

   meth buildGuessRecords(Guesses Feedbacks N ?Result)
      case Guesses of nil then Result = nil
      [] Guess|Gr then
         case Feedbacks of nil then
            Result = [record(guess: Guess feedback: nil roundNumber: N)]
         [] Feedback|Fr then
            Result = record(guess: Guess feedback: Feedback roundNumber: N)
                     |{self buildGuessRecords(Gr Fr N+1 $)}
         end
      end
   end

   meth buildFeedbackRecords(Feedbacks N ?Result)
      case Feedbacks of nil then Result = nil
      [] Feedback|Fr then
         Result = record(feedback: Feedback roundNumber: N)
                  |{self buildFeedbackRecords(Fr N+1 $)}
      end
   end
end
