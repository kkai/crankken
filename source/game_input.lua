-- Input handling for CrankKen puzzle game
-- Manages crank and button input for size selection and gameplay

local pd <const> = playdate

class("GameInput").extends()

-- Constants
local SIZES = {3, 4, 5, 6}
local QUARTER_ROTATION_DEGREES = 90
local HALF_ROTATION_DEGREES = 180
local FULL_ROTATION_DEGREES = 360

function GameInput:init()
    -- Crank position tracking
    self.last_crank_position = pd.getCrankPosition()
    self.crank_accumulator = 0
    self.size_crank_accumulator = 0
end

--- Handle input for size selection screen
-- @param current_size number: Currently selected puzzle size
-- @return number, boolean: new size, whether size changed
function GameInput:handle_size_selection(current_size)
    -- Handle button input
    local new_size = self:_handle_size_buttons(current_size)
    if new_size ~= current_size then
        return new_size, true
    end
    
    -- Handle crank input for size selection
    new_size = self:_handle_size_crank(current_size)
    if new_size ~= current_size then
        return new_size, true
    end
    
    return current_size, false
end

--- Handle button input for size selection (private method)
-- @param current_size number: Currently selected size
-- @return number: New size (same as current if no change)
function GameInput:_handle_size_buttons(current_size)
    if pd.buttonJustPressed(pd.kButtonUp) then
        for i, size in ipairs(SIZES) do
            if size == current_size and i > 1 then
                return SIZES[i - 1]
            end
        end
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        for i, size in ipairs(SIZES) do
            if size == current_size and i < #SIZES then
                return SIZES[i + 1]
            end
        end
    end
    
    return current_size
end

--- Handle crank input for size selection (private method)
-- @param current_size number: Currently selected size
-- @return number: New size (same as current if no change)
function GameInput:_handle_size_crank(current_size)
    local current_crank_position = pd.getCrankPosition()
    local crank_delta = self:_calculate_crank_delta(current_crank_position)
    
    self.size_crank_accumulator = self.size_crank_accumulator + crank_delta
    self.last_crank_position = current_crank_position
    
    -- Trigger size change on quarter rotation
    if math.abs(self.size_crank_accumulator) >= QUARTER_ROTATION_DEGREES then
        local current_index = self:_find_size_index(current_size)
        
        if self.size_crank_accumulator >= QUARTER_ROTATION_DEGREES then
            -- Clockwise rotation - next size
            if current_index < #SIZES then
                self.size_crank_accumulator = self.size_crank_accumulator - QUARTER_ROTATION_DEGREES
                return SIZES[current_index + 1]
            end
        elseif self.size_crank_accumulator <= -QUARTER_ROTATION_DEGREES then
            -- Counter-clockwise rotation - previous size
            if current_index > 1 then
                self.size_crank_accumulator = self.size_crank_accumulator + QUARTER_ROTATION_DEGREES
                return SIZES[current_index - 1]
            end
        end
    end
    
    return current_size
end

--- Handle input during gameplay
-- @param selected_cell table: Current selected cell {x, y}
-- @param puzzle_size number: Size of the puzzle grid
-- @param quit_button_selected boolean: Whether quit button is selected
-- @return table, boolean, boolean, string|nil: new_cell, new_quit_selected, moved, action
function GameInput:handle_game_input(selected_cell, puzzle_size, quit_button_selected)
    local moved = false
    local new_cell = {x = selected_cell.x, y = selected_cell.y}
    local new_quit_selected = quit_button_selected
    local action = nil
    
    -- Handle navigation
    new_cell, new_quit_selected, moved = self:_handle_navigation(
        selected_cell, 
        puzzle_size, 
        quit_button_selected
    )
    
    -- Handle action buttons
    action = self:_handle_action_buttons(quit_button_selected)
    if action then
        moved = true
    end
    
    -- Handle crank input (only when not on quit button)
    if not quit_button_selected then
        local crank_action = self:_handle_game_crank()
        if crank_action then
            action = crank_action
            moved = true
        end
        
        -- Handle menu button for clearing cells
        if pd.buttonJustPressed(pd.kButtonMenu) then
            action = "clear"
            moved = true
        end
    end
    
    return new_cell, new_quit_selected, moved, action
end

--- Handle navigation input (private method)
-- @param selected_cell table: Current selected cell
-- @param puzzle_size number: Size of the puzzle
-- @param quit_button_selected boolean: Whether quit button is selected
-- @return table, boolean, boolean: new_cell, new_quit_selected, moved
function GameInput:_handle_navigation(selected_cell, puzzle_size, quit_button_selected)
    local new_cell = {x = selected_cell.x, y = selected_cell.y}
    local new_quit_selected = quit_button_selected
    local moved = false
    
    if pd.buttonJustPressed(pd.kButtonUp) then
        if quit_button_selected then
            -- Move from quit button to bottom row of grid
            new_quit_selected = false
            new_cell.y = puzzle_size
            moved = true
        elseif selected_cell.y > 1 then
            new_cell.y = selected_cell.y - 1
            moved = true
        end
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        if not quit_button_selected and selected_cell.y < puzzle_size then
            new_cell.y = selected_cell.y + 1
            moved = true
        elseif not quit_button_selected and selected_cell.y == puzzle_size then
            -- Move from bottom row to quit button
            new_quit_selected = true
            moved = true
        end
    elseif pd.buttonJustPressed(pd.kButtonLeft) and not quit_button_selected and selected_cell.x > 1 then
        new_cell.x = selected_cell.x - 1
        moved = true
    elseif pd.buttonJustPressed(pd.kButtonRight) and not quit_button_selected and selected_cell.x < puzzle_size then
        new_cell.x = selected_cell.x + 1
        moved = true
    end
    
    return new_cell, new_quit_selected, moved
end

--- Handle action buttons (A and B) (private method)
-- @param quit_button_selected boolean: Whether quit button is selected
-- @return string|nil: Action name or nil
function GameInput:_handle_action_buttons(quit_button_selected)
    if pd.buttonJustPressed(pd.kButtonA) then
        if quit_button_selected then
            return "quit"
        else
            return "increment"
        end
    elseif pd.buttonJustPressed(pd.kButtonB) and not quit_button_selected then
        return "decrement"
    end
    
    return nil
end

--- Handle crank input for gameplay (private method)
-- @return string|nil: Action name or nil
function GameInput:_handle_game_crank()
    local current_crank_position = pd.getCrankPosition()
    local crank_delta = self:_calculate_crank_delta(current_crank_position)
    
    self.crank_accumulator = self.crank_accumulator + crank_delta
    self.last_crank_position = current_crank_position
    
    -- Trigger number change on half rotation
    if math.abs(self.crank_accumulator) >= HALF_ROTATION_DEGREES then
        if self.crank_accumulator >= HALF_ROTATION_DEGREES then
            self.crank_accumulator = self.crank_accumulator - HALF_ROTATION_DEGREES
            return "increment"
        elseif self.crank_accumulator <= -HALF_ROTATION_DEGREES then
            self.crank_accumulator = self.crank_accumulator + HALF_ROTATION_DEGREES
            return "decrement"
        end
    end
    
    return nil
end

--- Calculate crank delta with wraparound handling (private method)
-- @param current_position number: Current crank position
-- @return number: Delta with wraparound correction
function GameInput:_calculate_crank_delta(current_position)
    local delta = current_position - self.last_crank_position
    
    -- Handle wraparound at 0/360 degrees
    if delta > HALF_ROTATION_DEGREES then
        delta = delta - FULL_ROTATION_DEGREES
    elseif delta < -HALF_ROTATION_DEGREES then
        delta = delta + FULL_ROTATION_DEGREES
    end
    
    return delta
end

--- Find index of size in SIZES array (private method)
-- @param size number: Size to find
-- @return number: Index of size in SIZES array
function GameInput:_find_size_index(size)
    for i, s in ipairs(SIZES) do
        if s == size then
            return i
        end
    end
    return 1  -- Default to first size if not found
end