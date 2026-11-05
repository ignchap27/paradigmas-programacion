%% ============================================================================
%% Main game controller that manages the overall game flow
%% ============================================================================
%% Color enumeration - valid colors in the game
%% Type: Color :: red | blue | green | yellow | orange | purple
%% ============================================================================
declare 

   fun {CountBlacks Code Guess}
      case Code#Guess
      of (C|Cs)#(G|Gs) then
         if C == G then 1 + {CountBlacks Cs Gs}
         else {CountBlacks Cs Gs}
         end
      else 0
      end
   end

   fun {Occurrences Color L}
      {Length {Filter L fun {$ X} X == Color end}}
   end

   fun {CountCommon Code Guess}
      {FoldL {Map [red blue green yellow orange purple]
              fun {$ C} {Min {Occurrences C Code} {Occurrences C Guess}} end}
       Number.'+' 0}
   end

   fun {Repeat X N}
      if N =< 0 then nil
      else X|{Repeat X N-1}
      end
   end

   fun {StartGame Code}
      %% Starts a new game session with a codemaker with a defined secret code and the rounds played 
      %% Input: The code
      %% Output: A code maker with the code
      
      %% Your code here
      codemaker(code:Code rounds:0)
   end
   
   fun {PlayRound Codemaker Guess}
      %% Executes one round of the game (guess + feedback)
      %% Input: the code maker and the guess from the codebreaker  
      %% Output: [FeedbackClue] % Black and white Clues received
      %%          round, the number of rounds played so far   
      %% Your code here
      round(feedback:{EvaluateGuess Codemaker Guess}
            rounds:Codemaker.rounds + 1
            codemaker:codemaker(code:Codemaker.code rounds:Codemaker.rounds + 1))
   end
   
   fun {GetGameStatus Feedback Rounds}
      %% Returns current game status
      %% Input: Game Feedback
      %%        The number of rounds played so far 
      %% Output: Result :: GameStatus - Current status of the game
      %%         GameStatus :: 'playing' | 'won' | 'lost' 
      %% Your code here
      if Feedback.blackClues == 4 then won
      elseif Rounds >= 12 then lost
      else playing
      end
   end
   
   fun {GetCurrentRound Codemaker}
      %% Returns current round number
      %% Input: Codemaker
      %% Output: Result :: Int - Current round number (1-12)
      %% Your code here
      Codemaker.rounds + 1
   end
   
   fun {GetRemainingRounds Codemaker}
      %% Returns number of rounds left
      %% Input: Codemaker
      %% Output: Result :: Int - Number of rounds remaining (0-11)
      %% Your code here
      12 - {GetCurrentRound Codemaker}
   end
   
   fun {EvaluateGuess Codemaker Guess}
      %% Evaluates a guess against the secret code
      %% Input: Codebreaker
      %%        Guess :: [Color] - List of exactly 4 colors representing the guess
      %% Output: [Result] :: blackClues: Int     % Number of correct color & position
      %%            whiteClues: Int            % Number of correct color, wrong position  
      %%            ClueList: [FeedbackClue]   % List of individual Clue results
      %% Your code here
      local
         Black = {CountBlacks Codemaker.code Guess}
         White = {CountCommon Codemaker.code Guess} - Black
      in
         feedback(blackClues:Black
                  whiteClues:White
                  'ClueList':{Append {Repeat black Black} {Repeat white White}})
      end
   end

   fun {GetSecretCode Codemaker}
      %% Returns the current secret code (for testing/debugging)
      %% Input: None
      %% Output: Result :: [Color] | nil - Secret code or nil if not set
      %% Note: Should only be used for testing, breaks game in normal play
      %% Your code here
      Codemaker.code
   end