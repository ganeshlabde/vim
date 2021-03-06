if has('messagequeue')

set nocompatible
set nocursorline

python << EOF
# adapted from https://gist.github.com/sanchitgangwar/2158084
import vim
from random import randint
from time import sleep
from threading import Thread, Lock
 
buf = vim.current.buffer
empty = ' ' * 80
buf[0] = empty
for n in xrange(20):
    buf.append(empty)


def addstr(lnum, cnum, string):
    line = buf[lnum]
    line = line[0:cnum] + string + line[cnum + len(string):]
    buf[lnum] = line


key = 'right'
prevKey = 'right'
score = 0
snake = [[4,10], [4,9], [4,8]]                                     # Initial snake co-ordinates
food = [10,20]                                                     # First food co-ordinates
lock = Lock()
     
def run_game():
    global key, prevKey, score, snake, food

    timeout = None
     
    addstr(food[0], food[1], '*')                                      # Prints the food
     
    while key != 'esc':
	lock.acquire()
	if key == 'space':                                             # If SPACE BAR is pressed, wait for another
	    key = None
	    while key != 'space':
		lock.release()
		sleep(timeout)
		lock.acquire()
	    key = prevKey
	    lock.release()
	    continue
     
	# Calculates the new coordinates of the head of the snake. NOTE: len(snake) increases.
	# This is taken care of later at [1].
	snake.insert(0, [snake[0][0] + (key == 'down' and 1) + (key == 'up' and -1), snake[0][1] + (key == 'left' and -1) + (key == 'right' and 1)])
     
	# If snake crosses the boundaries, make it enter from the other side
	if snake[0][0] == 0: snake[0][0] = 18
	if snake[0][1] == 0: snake[0][1] = 58
	if snake[0][0] == 19: snake[0][0] = 1
	if snake[0][1] == 59: snake[0][1] = 1
     
	# Exit if snake crosses the boundaries (Uncomment to enable)
	#if snake[0][0] == 0 or snake[0][0] == 19 or snake[0][1] == 0 or snake[0][1] == 59: break
     
	# If snake runs over itself
	if snake[0] in snake[1:]: break

	timeout = 0.001 * (150 - (len(snake)/5 + len(snake)/10)%120)   # Increases the speed of Snake as its length increases
	prevKey = key                                                  # Previous key pressed
	lock.release()
	vim.defer('Update')
	sleep(timeout)
    vim.defer('End')
EOF
 
function Update()
python << EOF
lock.acquire()
if snake[0] == food:                                            # When snake eats the food
    food = []
    score += 1
    while food == []:
	food = [randint(1, 18), randint(1, 58)]                 # Calculating next food's coordinates
	if food in snake: food = []
    addstr(food[0], food[1], '*')
else:    
    last = snake.pop()                                          # [1] If it does not eat the food, length decreases
    addstr(last[0], last[1], ' ')
addstr(snake[0][0], snake[0][1], '#')
addstr(0, 2, 'Score : ' + str(score) + ' ')                    # Printing 'Score' and
addstr(0, 27, ' SNAKE / MOVEMENTS(hjkl) EXIT(i) PAUSE(space) ')
lock.release()
EOF
endfunction

function End()
unmap k
unmap j
unmap h
unmap l
unmap i
unmap <space>
python << EOF
buf[:] = None
buf.append("Score - " + str(score))
buf.append("http://bitemelater.in")
EOF
endfunction

function KeyPress(k)
python << EOF
lock.acquire()
key = vim.eval('a:k')
lock.release()
EOF
endfunction

nnoremap k :call KeyPress('up')<cr>
nnoremap j :call KeyPress('down')<cr>
nnoremap h :call KeyPress('left')<cr>
nnoremap l :call KeyPress('right')<cr>
nnoremap i :call KeyPress('esc')<cr>
nnoremap <space> :call KeyPress('space')<cr>

python << EOF
game = Thread(target=run_game)
game.daemon = True
game.start()
EOF
endif
