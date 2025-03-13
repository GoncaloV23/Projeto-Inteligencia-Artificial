(defun example_state () (state_constructer (ramdom_board)))
;(defun example_state_with_players () (first_play (first_play (example_state) 0) 0))



;Board definition constructer and auxiliare funcs
(defstruct board
    (points)
)
(defun board_constructer (points_list)
"Construtor da estrutura de dados board"
    (make-board :points points_list )
)
(defun compare_board (board1 board2)
"Compara 2 Board e retorna t se forem iguais"
  (every #'(lambda (a) (= 0 a)) 
    (mapcar 
        #'(lambda (a b) 
          (cond ((and (null a) (null b)) 0)
                ((null a) b)
                ((null b) (* a -1))
                (t (- b a))
          )
        )
        (remove nil (apply #'append (board-points board1)))
        (remove nil (apply #'append (board-points board2)))
    )
  )
)


;State definition
(defstruct state
    (board)
    (players (list (make-player) (make-player)))
    (play_turn -1)
)
(defun state_constructer (points_list)
"Construtor da estrutura de dados State com parametros default"
    (make-state 
        :board (board_constructer points_list)
    )
)
(defun state_constructer_with_params (points_list player1 player2 play_turn)
"Construtor da estrutura de dados State"
    (make-state 
        :board (board_constructer points_list)
        :players (list player1 player2)
        :play_turn play_turn
    )
)
(defun get_state_square (state position)
"Retorna o valor dos pontos em uma determina posição"
  (if (or (NULL state) (NULL position))
    nil
    (let ((x (horse_position-x position)) (y (horse_position-y position)))
      (if (or (>= x 10) (< x 0) (>= y 10) (< y 0)) nil
        (nth x (nth y (get_state_board_points state)))
      )
    )
  )
)
(defun get_state_board_points (state)
"Retorna a lista de pontos"
    (board-points (state-board state))
)
(defun get_player (state player) 
"Retorna o player1 se player = -1 ou player2 se player = 1"
  (cond ((= player -1) (nth 0 (state-players state)))
        ((= player 1) (nth 1 (state-players state)))
        (t nil)
  )
)
(defun get_play_turn (state)
  (state-play_turn state)
)
(defun compare_state (state1 state2)
"Compara 2 State e retorna t se forem iguais"
  (if (or (null state1) (null state2))
    nil
    (let* ( (player1_state1 (state-player1 state1)) 
            (player2_state1 (state-player2 state1))
            (player1_state2 (state-player1 state2)) 
            (player2_state2 (state-player2 state2))
            (board1 (state-board state1)) 
            (board2 (state-board state2))
            (play_turn1 (state-play_turn state1))
            (play_turn2 (state-play_turn state2))
          )
      (and  (compare_player player1_state1 player1_state2) 
            (compare_player player2_state1 player2_state2) 
            (compare_board board1 board2)
            (= play_turn1 play_turn2)
      )
    )
  )
)
(defun switch_play_turn (state)
"Troca a vez do jogador"
  (state_constructer_with_params 
    (get_state_board_points state)
    (get_player state -1)
    (get_player state 1)
    (* (get_play_turn state) -1)
  )
)

;;Player definition
(defstruct player
    (points 0)
    (position (position_constructer -1 -1))
    (path '())
)
(defun player_constructer (points position path)
"Construtor da estrutura de dados Player"
    (make-player 
        :points points
        :position position
        :path path
    )
)
(defun compare_player (player1 player2)
    (if (or (null player1) (null player2))
        nil
        (let* ( (points1 (player-points player1)) 
                (points2 (player-points player2))
                (position1 (player-position player1)) 
                (position2 (player-position player2))
            )
            (and    (= points1 points2) 
                    (compare_position position1 position2)
            )
        )
    )
)


;;Horse_Position definition
(defstruct horse_position
  (x -1)
  (y -1)
)
(defun position_constructer (x y)
"Construtor de uma estrutura de dados Horse_position"
  (make-horse_position
    :x x
    :y y
  )
)
(defun compare_position (pos1 pos2)
"Compara 2 Horse_position e retorna t se forem iguais"
  (and 
    (= (horse_position-x pos1) (horse_position-x pos2))
    (= (horse_position-y pos1) (horse_position-y pos2))
  )
)



;plays
(defun first_play (state init_x)
"Jogada inicial. init_x = posição inicial na linha 0 (se play_turn do state = -1) ou 9 (se play_turn do state = 1) "
  (cond ((or (null state) (null init_x)) nil)
        ((= (get_play_turn state) -1) (move_piece state (list (+ init_x 1) 1)))
        (t (move_piece state (list (+ init_x 1) 10)))
  )
)
(defun move_piece (state movement_vector)
"Jogada normal. Utiliza o movement_vector para transformar a posição do cavalo branco (se play_turn do state = -1) ou preto (se play_turn do state = 1)"
  (if (NULL state) nil
    (let* ( (play_turn (get_play_turn state))
            (current_pos (player-position(get_player state play_turn))) 
            (other_player  (player-position(get_player state (* play_turn -1))))
            (not_allowed_pos (append 
                (get_possible_positions other_player) 
                (list other_player)
              ))
              (new_pos (transform_position current_pos movement_vector))
              (points (get_state_square state new_pos))
          )
        (cond ((or (NULL new_pos) (NULL points)) nil)
              ((not (NULL (member new_pos not_allowed_pos :test #'compare_position))) nil)
              (T  (calculate_new_state state new_pos (simetry_double_rule state points)))      
        )
    )
  )
)


;auxiliary functions
(defun transform_position (position vector)
"Calcula o novo ponto a partir de um vector de movimento"
  (let* ( (x (+ (horse_position-x position) (nth 0 vector)))
          (y (+ (horse_position-y position) (nth 1 vector)))
        )
      (cond 
        ((or (< x 0) (< y 0)) (> x 9) (> y 9) NIL)
        (T (position_constructer x y))
      )
  )
)
(defun calculate_new_state (state new_position rule_position)
"Calcula o novo estado depois do movimento do cavalo"
  (if (= (get_play_turn state) -1)
    (state_constructer_with_params 
      (set_board_value 
        (set_board_value (get_state_board_points state) new_position NIL)
        rule_position
        NIL
      )
      (get_new_player (get_player state -1) state new_position)
      (get_player state 1)
      1
    )
    (state_constructer_with_params 
      (set_board_value 
        (set_board_value (get_state_board_points state) new_position NIL)
        rule_position
        NIL
      )
      (get_player state -1)
      (get_new_player (get_player state 1) state new_position)
      -1
    )
  )
)
(defun get_new_player (player state new_position)
"Cria um novo player a partir do estado e da nova posição"
  (player_constructer 
    (+ (player-points player) (get_state_square state new_position))
    new_position
    (append (player-path player) (list new_position))
  )
)
(defun set_board_value (board_list position value)
"Troca o valor de uma celula"
  (if (or (< (horse_position-y position) 0) (> (horse_position-y position) 9))
    board_list
    (let* ( (line (nth (horse_position-y position) board_list))
            (new_line (set_list_value (horse_position-x position) line value))
          )
        (set_list_value (horse_position-y position) board_list new_line)
    )
  )
)
(defun set_list_value (index line value)
"Troca o valor de index da lista"
  (if (or (< index 0) (> index 9))
    line
    (append (append (subseq line 0 index) (list value))
            (cdr (subseq line index))
    )
  )
)
(defun calculate_vector (current_pos new_pos)
"Calcula o vetor de movimento entre 2 posições"
  (list (- (horse_position-x new_pos) (horse_position-x current_pos)) (- (horse_position-y new_pos) (horse_position-y current_pos)))
)
(defun simetry_double_rule (state points)
"Enforça as resgras de simetria ou double do jogo, se o numero for de duplo algarismo 
troca o de duplo algarimo mais alto que encontra por nil caso contrario 
troca o de algarimos inversos por nil, e retorna a sua posição"
  (cond ((or (NULL state) (< points 0) (> points 99)) NIL)
        ((is_double_algarisms points) 
          (find_highest_double_algarisms 
              (get_state_board_points state)
              points
          )
        )
        (T
          (find_inverse 
            (get_state_board_points state) 
            points
          )
        )
  )
)
(defun find_highest_double_algarisms (board_list value)
"Encontra o maior numero de duplo algarismo que não seja igual a value"
  (find_one_list_element board_list (remove value (list 99 88 77 66 55 44 33 22 11 0)))
)
(defun find_one_list_element (board_list list)
"Encontra um numero de uma lista no Board"
  (let ((pos (seach_board board_list (car list))))
    (if (and (NULL pos) (> (length list) 1)) 
      (find_one_list_element board_list (cdr list)) 
      pos
    )
  )
)
(defun find_inverse (board_list value)
"Encontra o numero com os algarismo invertidos"
  (seach_board  
        board_list 
        (+ (* (mod value 10) 10) (floor (/ value 10)))
  )
)
(defun seach_board (board_list value)
"Encontra um numero no Board"
  (let ((index (position value (apply #'append board_list) :test #'equal)))
    (if (NULL index) NIL
      (position_constructer (mod index 10) (floor (/ index 10)))
    )
  )
)
(defun is_double_algarisms (numb)
"Verifica se o numero é de duplo algarismo" 
  (= (mod numb 10) (floor (/ numb 10)))
)
;minmax (state depth heuristic expand)
;computer functions
(defun computer_move_minmax (state max_time)
"Calcula a proxima jogada com minmax"
  (if (= (get_play_turn state) -1)
    (minmax state 5 #'h1_player1 #'get_all_possible_plays)
    (minmax state 5 #'h1_player2 #'get_all_possible_plays)
  )
)
(defun computer_move (state max_time)
"Calcula a proxima jogada com alfabeta"
  (if (= (get_play_turn state) -1)
    (alfabeta state 5 #'h1_player1 #'get_all_possible_plays max_time)
    (alfabeta state 5 #'h1_player2 #'get_all_possible_plays max_time)
  )
)


;heuristics
(defun h1 (state play_turn)
"Pontos do jogador - pontos do jogador inimigo"
  (- (player-points (get_player state play_turn)) (player-points(get_player state (* play_turn -1))))
)
(defun h1_player1 (state)
"Pontos do jogador1 - pontos do jogador2"
    (h1 state -1)
)
(defun h1_player2 (state)
"Pontos do jogador2 - pontos do jogador1"
    (h1 state 1)
)

;operators
(defun get_possible_plays (state)
"Retorna as todas jogada possiveis a partir de um estado"
  (remove nil 
    (mapcar 
      #'(lambda (vec) 
          (move_piece state vec)
      )
      (horse_possible_vectors)
    )
  ) 
)
(defun get_possible_initial_plays (state)
"Retorna as todas jogada iniciais possiveis a partir de um estado"
  (remove nil 
    (mapcar 
      #'(lambda (init_x) 
          (first_play state init_x)
      )
      '(0 1 2 3 4 5 6 7 8 9)
    )
  ) 
)
(defun get_all_possible_plays (state)
"Se for as jogadas inicias utiliza get_possible_initial_plays se não utiliza get_possible_plays"
  (if (is_first_move state)
    (get_possible_initial_plays state)
    (get_possible_plays state)
  )
)
(defun is_first_move (state)
"Verifica se é primeira jogado do jogador"
  (let ((player (get_player state (get_play_turn state))))
    (if (< (horse_position-x (player-position player)) 0)
      t
      nil
    )
  )
)
;auxiliary functions
(defun horse_possible_vectors () 
"Retorna uma lista com todos os vetores que o cavalo pode fazer."
  '((-1 -2) (1 -2) (2 -1) (2 1) (-1 2) (1 2) (-2 1) (-2 -1))
)
(defun check_player_move (new_vector)
"Verifica se o new_vector é igual a um dos vetores que o cavalo pode ter"
  (if (NULL (member 
              new_vector
              (horse_possible_vectors)
              :test #'equalp
            ))
      nil
      t
  )
)
(defun get_possible_positions (pos)
"Retorna uma lista com todas as novas posições do cavalo."
  (remove nil 
    (mapcar 
      #'(lambda (vec) 
          (transform_position pos vec)
      )
      (horse_possible_vectors)
    )
  ) 
)




;Ramdom board
(defun ramdom_board ()
"Cria um tabuleiro a sorte"
    (let ((numbs (shuffle (loop for num from 0 to 99 collect num))))
        (list 
            (subseq numbs 0 10)
            (subseq numbs 10 20)
            (subseq numbs 20 30)
            (subseq numbs 30 40)
            (subseq numbs 40 50)
            (subseq numbs 50 60)
            (subseq numbs 60 70)
            (subseq numbs 70 80)
            (subseq numbs 80 90)
            (subseq numbs 90 100)
            
        )
    )
    
)
(defun shuffle (lst)
"Baralhas os elementos de uma lista recebida como parametro. "
  (loop for i from (1- (length lst)) downto 1
        do (rotatef (elt lst i) (elt lst (random (1+ i)))))
  lst
)