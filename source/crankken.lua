import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/ui"
import "puzzle_generator"
import "best_times"
import "game_input"
import "game_ui"

local pd <const> = playdate
local gfx <const> = pd.graphics

class("CrankKen").extends()

-- Game states
local STATE_SIZE_SELECTION = 1
local STATE_PLAYING = 2
local STATE_COMPLETED = 3

function CrankKen:init()
    -- Initialize game state
    self.state = STATE_SIZE_SELECTION
    self.selected_size = 5  -- Start with 5x5 as middle option
    self.puzzle = nil
    self.player_grid = nil
    self.selected_cell = {x = 1, y = 1}
    self.cell_size = 33  -- Default value, will be recalculated in start_game
    self.quit_button_selected = false
    
    -- Timer tracking
    self.puzzle_start_time = 0
    self.completion_time = 0
    
    -- Initialize modules
    self.puzzle_generator = PuzzleGenerator()
    self.best_times = BestTimes()
    self.input = GameInput()
    self.ui = GameUI()
    
    -- Grid positioning (calculated in start_game)
    self.grid_offset_x = 0
    self.grid_offset_y = 0
end

function CrankKen:update()
    if self.state == STATE_SIZE_SELECTION then
        self:update_size_selection()
    elseif self.state == STATE_PLAYING then
        self:update_game()
    elseif self.state == STATE_COMPLETED then
        self:update_completed()
    end
end

function CrankKen:update_size_selection()
    local new_size, size_changed = self.input:handle_size_selection(self.selected_size)
    
    if size_changed then
        self.selected_size = new_size
        self:show_size_selection()
    end
    
    if pd.buttonJustPressed(pd.kButtonA) then
        self:start_game(self.selected_size)
        self:draw_game()
    end
end

function CrankKen:update_game()
    local new_cell, new_quit_selected, moved, action = self.input:handle_game_input(
        self.selected_cell, 
        self.puzzle.size, 
        self.quit_button_selected
    )
    
    -- Update game state
    self.selected_cell = new_cell
    self.quit_button_selected = new_quit_selected
    
    -- Handle actions
    if action then
        if action == "quit" then
            self:show_size_selection()
            return
        elseif action == "increment" or action == "decrement" or action == "clear" then
            self:handle_cell_action(action)
            moved = true
        end
    end
    
    -- Always redraw to keep timer updated
    self:draw_game()
    
    if moved and self:check_completion() then
        self:handle_puzzle_completion()
    end
end

function CrankKen:handle_cell_action(action)
    local current_value = self.player_grid[self.selected_cell.x][self.selected_cell.y]
    
    if action == "increment" then
        current_value = (current_value + 1) % (self.puzzle.size + 1)
    elseif action == "decrement" then
        current_value = current_value - 1
        if current_value < 0 then
            current_value = self.puzzle.size
        end
    elseif action == "clear" then
        current_value = 0
    end
    
    self.player_grid[self.selected_cell.x][self.selected_cell.y] = current_value
end

function CrankKen:handle_puzzle_completion()
    -- Calculate completion time
    self.completion_time = pd.getCurrentTimeMilliseconds() - self.puzzle_start_time
    
    -- Update best time if this is a new record
    self.best_times:update_best_time(self.puzzle.size, self.completion_time)
    
    self.state = STATE_COMPLETED
    self:draw_game()  -- Redraw the game first
    self.ui:draw_completion_popup(self.completion_time)  -- Then draw popup overlay
end

function CrankKen:update_completed()
    if pd.buttonJustPressed(pd.kButtonA) then
        self:show_size_selection()
    end
end

function CrankKen:show_size_selection()
    self.state = STATE_SIZE_SELECTION
    self.ui:draw_size_selection(self.selected_size, self.best_times)
end

function CrankKen:start_game(size)
    self.state = STATE_PLAYING
    self.puzzle = self:generate_puzzle(size)
    self.player_grid = {}
    
    -- Timer will be started when puzzle is first drawn
    self.puzzle_start_time = 0
    
    -- Reset quit button selection
    self.quit_button_selected = false
    
    -- Calculate dynamic cell size to fit on screen (with margins for UI elements)
    local max_grid_width, max_grid_height
    
    if size == 9 then
        -- Use more of the screen for 9x9 puzzles
        max_grid_width = 390   -- Use even more width for 9x9
        max_grid_height = 230  -- Use even more height for 9x9
    else
        max_grid_width = 360   -- Leave room for timer and quit button
        max_grid_height = 200  -- Leave room for timer at top
    end
    
    local max_cell_size_for_width = math.floor(max_grid_width / size)
    local max_cell_size_for_height = math.floor(max_grid_height / size)
    self.cell_size = math.min(max_cell_size_for_width, max_cell_size_for_height, 33)  -- Cap at 33 for small grids
    
    -- Calculate centered grid position
    local grid_width = size * self.cell_size
    local grid_height = size * self.cell_size
    self.grid_offset_x = (400 - grid_width) / 2
    self.grid_offset_y = (240 - grid_height) / 2
    
    -- Initialize empty player grid
    for x = 1, size do
        self.player_grid[x] = {}
        for y = 1, size do
            self.player_grid[x][y] = 0
        end
    end
    
    self.selected_cell = {x = 1, y = 1}
end

function CrankKen:generate_puzzle(size)
    return self.puzzle_generator:generate_puzzle(size)
end

function CrankKen:draw_game()
    -- Start timer on first draw
    if self.puzzle_start_time == 0 then
        self.puzzle_start_time = pd.getCurrentTimeMilliseconds()
    end
    
    self.ui:draw_game(
        self.puzzle,
        self.player_grid,
        self.selected_cell,
        self.quit_button_selected,
        self.puzzle_start_time,
        self.grid_offset_x,
        self.grid_offset_y,
        self.cell_size
    )
end

function CrankKen:check_completion()
    -- Check if all cells are filled
    for x = 1, self.puzzle.size do
        for y = 1, self.puzzle.size do
            if self.player_grid[x][y] == 0 then
                return false
            end
        end
    end
    
    -- Check row and column constraints
    for i = 1, self.puzzle.size do
        local row_values = {}
        local col_values = {}
        for j = 1, self.puzzle.size do
            local row_val = self.player_grid[i][j]
            local col_val = self.player_grid[j][i]
            
            if row_values[row_val] or col_values[col_val] then
                return false
            end
            row_values[row_val] = true
            col_values[col_val] = true
        end
    end
    
    -- Check cage constraints
    for _, cage in ipairs(self.puzzle.cages) do
        if not self:check_cage(cage) then
            return false
        end
    end
    
    return true
end

function CrankKen:check_cage(cage)
    local values = {}
    for _, cell in ipairs(cage.cells) do
        table.insert(values, self.player_grid[cell[1]][cell[2]])
    end
    
    if cage.operation == "=" then
        return values[1] == cage.target
    elseif cage.operation == "+" then
        local sum = 0
        for _, v in ipairs(values) do
            sum += v
        end
        return sum == cage.target
    elseif cage.operation == "x" then
        local product = 1
        for _, v in ipairs(values) do
            product *= v
        end
        return product == cage.target
    elseif cage.operation == "-" then
        if #values == 2 then
            return math.abs(values[1] - values[2]) == cage.target
        end
    elseif cage.operation == "/" then
        if #values == 2 then
            return math.max(values[1], values[2]) / math.min(values[1], values[2]) == cage.target
        end
    end
    
    return false
end