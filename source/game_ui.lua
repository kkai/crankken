-- User interface rendering for CrankKen puzzle game
-- Handles all drawing functions for different game screens

local pd <const> = playdate
local gfx <const> = pd.graphics

class("GameUI").extends()

-- Constants
local GRID_SIZES = {3, 4, 5, 6, 7, 8, 9}
local TITLE_BOLD_OFFSET = 1
local BEST_TIME_OFFSET = 15

function GameUI:init()
    self.small_font = gfx.font.new("fonts/Mini Sans")
end

--- Draw the size selection screen
-- @param selected_size number: Currently selected puzzle size
-- @param best_times BestTimes: Best times manager instance
function GameUI:draw_size_selection(selected_size, best_times)
    gfx.clear()
    
    -- Draw title with bold effect
    self:_draw_title()
    
    -- Draw size selection options
    self:_draw_size_options(selected_size)
    
    -- Draw start game instruction
    gfx.drawText("Ⓐ to start a game", 50, 210)
    
    -- Draw grid preview on the right
    self:_draw_grid_preview(selected_size, best_times)
    
    -- Draw control instructions
    self:_draw_control_instructions()
end

--- Draw the game title with bold effect (private method)
function GameUI:_draw_title()
    local system_font = gfx.getSystemFont()
    gfx.setFont(system_font)
    
    -- Bold effect: draw twice with slight offset
    gfx.drawText("CrankKen", 50, 20)
    gfx.drawText("CrankKen", 50 + TITLE_BOLD_OFFSET, 20)
end

--- Draw size selection options (private method)
-- @param selected_size number: Currently selected size
function GameUI:_draw_size_options(selected_size)
    for i, size in ipairs(GRID_SIZES) do
        local y = 50 + (i - 1) * 22  -- Moved up to start right under the title
        local text = size .. "x" .. size
        
        if size == selected_size then
            gfx.fillRect(50, y - 3, 100, 20)  -- Smaller highlight box
            gfx.setImageDrawMode(gfx.kDrawModeInverted)
        end
        
        gfx.drawText(text, 60, y)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

--- Draw control instructions (private method)
function GameUI:_draw_control_instructions()
    local system_font = gfx.getSystemFont()
    gfx.setFont(system_font)
    
    local control_text = "⬆⬇ select size"
    local text_width = system_font:getTextWidth(control_text)
    local dialog_end_x = 150
    local screen_end_x = 400
    local available_width = screen_end_x - dialog_end_x
    local center_x = dialog_end_x + available_width / 2
    
    gfx.drawText(control_text, center_x - text_width / 2, 210)
    
    -- Reset to default font
    gfx.setFont(gfx.getFont())
end

--- Draw grid preview with best time (private method)
-- @param size number: Grid size to preview
-- @param best_times BestTimes: Best times manager instance
function GameUI:_draw_grid_preview(size, best_times)
    -- Calculate preview dimensions
    local maxGridSize = 120
    local previewCellSize = math.floor(maxGridSize / size)
    local gridPixelSize = size * previewCellSize
    
    -- Calculate centered position
    local dialogEndX = 150
    local screenEndX = 400
    local availableWidth = screenEndX - dialogEndX
    local previewStartX = dialogEndX + (availableWidth - gridPixelSize) / 2
    local previewStartY = (240 - gridPixelSize) / 2
    
    -- Draw best time above grid
    self:_draw_best_time(size, best_times, previewStartX, previewStartY)
    
    -- Draw grid outline
    self:_draw_preview_grid_lines(size, previewStartX, previewStartY, previewCellSize)
end

--- Draw best time text above preview grid (private method)
-- @param size number: Grid size
-- @param best_times BestTimes: Best times manager
-- @param startX number: Grid start X position
-- @param startY number: Grid start Y position
function GameUI:_draw_best_time(size, best_times, startX, startY)
    gfx.setFont(self.small_font)
    
    local timeText = best_times:format_time(best_times:get_best_time(size))
    local bestTimeText = "Best Time: " .. timeText
    local bestTimeX = startX  -- Left align with grid
    local bestTimeY = startY - BEST_TIME_OFFSET
    
    gfx.drawText(bestTimeText, bestTimeX, bestTimeY)
    
    -- Reset font
    gfx.setFont(gfx.getFont())
end

--- Draw preview grid lines (private method)
-- @param size number: Grid size
-- @param startX number: Grid start X position
-- @param startY number: Grid start Y position
-- @param cellSize number: Size of each cell
function GameUI:_draw_preview_grid_lines(size, startX, startY, cellSize)
    gfx.setLineWidth(1)
    
    -- Vertical lines
    for x = 0, size do
        local screenX = startX + x * cellSize
        gfx.drawLine(screenX, startY, screenX, startY + size * cellSize)
    end
    
    -- Horizontal lines
    for y = 0, size do
        local screenY = startY + y * cellSize
        gfx.drawLine(startX, screenY, startX + size * cellSize, screenY)
    end
end

function GameUI:draw_game(puzzle, player_grid, selected_cell, quit_button_selected, puzzle_start_time, grid_offset_x, grid_offset_y, cell_size)
    gfx.clear()
    
    -- Draw elapsed time in upper right corner
    if puzzle_start_time > 0 then
        local elapsed_ms = pd.getCurrentTimeMilliseconds() - puzzle_start_time
        local elapsed_seconds = math.floor(elapsed_ms / 1000)
        local minutes = math.floor(elapsed_seconds / 60)
        local seconds = elapsed_seconds % 60
        local time_text = string.format("%02d:%02d", minutes, seconds)
        
        -- Use system font for timer consistency
        local system_font = gfx.getSystemFont()
        gfx.setFont(system_font)
        local text_width = system_font:getTextWidth(time_text)
        gfx.drawText(time_text, 400 - text_width - 10, 10)
        
        -- Reset to default font for game drawing
        gfx.setFont(gfx.getFont())
    end
    
    -- Draw quit button in bottom right corner
    local quit_text = "Quit"
    local font = gfx.getFont()
    local quit_width = font:getTextWidth(quit_text)
    local quit_x = 400 - quit_width - 10
    local quit_y = 240 - 20
    
    if quit_button_selected then
        -- Highlight quit button when selected (cover whole button)
        local text_height = font:getHeight()
        gfx.fillRect(quit_x - 2, quit_y - 2, quit_width + 4, text_height + 4)
        gfx.setImageDrawMode(gfx.kDrawModeInverted)
    end
    
    gfx.drawText(quit_text, quit_x, quit_y)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    
    -- First pass: Draw cage boundaries and backgrounds
    self:draw_cage_boundaries(puzzle, grid_offset_x, grid_offset_y, cell_size)
    
    -- Second pass: Draw grid and numbers
    for x = 1, puzzle.size do
        for y = 1, puzzle.size do
            local screen_x = grid_offset_x + (x - 1) * cell_size
            local screen_y = grid_offset_y + (y - 1) * cell_size
            
            -- Highlight selected cell (only when not on quit button)
            if x == selected_cell.x and y == selected_cell.y and not quit_button_selected then
                gfx.fillRect(screen_x + 2, screen_y + 2, cell_size - 4, cell_size - 4)
                gfx.setImageDrawMode(gfx.kDrawModeInverted)
            end
            
            -- Draw number if entered
            local value = player_grid[x][y]
            if value > 0 then
                -- Use system font for user input numbers
                local system_font = gfx.getSystemFont()
                gfx.setFont(system_font)
                
                local text_x = screen_x + cell_size / 2 - 2
                local text_y = screen_y + cell_size / 2 - 8
                gfx.drawText(tostring(value), text_x, text_y)
                
                -- Reset to default font
                gfx.setFont(gfx.getFont())
            end
            
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
    end
    
    -- Third pass: Draw cage targets
    self:draw_cage_targets(puzzle, selected_cell, grid_offset_x, grid_offset_y, cell_size)
end

function GameUI:draw_cage_boundaries(puzzle, grid_offset_x, grid_offset_y, cell_size)
    gfx.setLineWidth(3)
    
    for _, cage in ipairs(puzzle.cages) do
        if #cage.cells > 0 then
            -- Create a set for quick lookup of cells in this cage
            local cellSet = {}
            for _, cell in ipairs(cage.cells) do
                cellSet[cell[1] .. "," .. cell[2]] = true
            end
            
            -- For each cell in the cage, draw thick borders where needed
            for _, cell in ipairs(cage.cells) do
                local x, y = cell[1], cell[2]
                local screen_x = grid_offset_x + (x - 1) * cell_size
                local screen_y = grid_offset_y + (y - 1) * cell_size
                
                -- Check each edge and draw thick border if not connected to same cage
                -- Top edge
                if y == 1 or not cellSet[(x) .. "," .. (y-1)] then
                    gfx.drawLine(screen_x, screen_y, screen_x + cell_size, screen_y)
                end
                
                -- Bottom edge
                if y == puzzle.size or not cellSet[(x) .. "," .. (y+1)] then
                    gfx.drawLine(screen_x, screen_y + cell_size, screen_x + cell_size, screen_y + cell_size)
                end
                
                -- Left edge
                if x == 1 or not cellSet[(x-1) .. "," .. (y)] then
                    gfx.drawLine(screen_x, screen_y, screen_x, screen_y + cell_size)
                end
                
                -- Right edge
                if x == puzzle.size or not cellSet[(x+1) .. "," .. (y)] then
                    gfx.drawLine(screen_x + cell_size, screen_y, screen_x + cell_size, screen_y + cell_size)
                end
            end
        end
    end
    
    gfx.setLineWidth(1)
end

function GameUI:draw_cage_targets(puzzle, selected_cell, grid_offset_x, grid_offset_y, cell_size)
    -- Draw cage targets in the top-left corner of the first cell
    for _, cage in ipairs(puzzle.cages) do
        if #cage.cells > 0 then
            local first_cell = cage.cells[1]
            local screen_x = grid_offset_x + (first_cell[1] - 1) * cell_size + 3
            local screen_y = grid_offset_y + (first_cell[2] - 1) * cell_size + 3
            
            local target_text
            if cage.operation == "/" then
                -- Format division targets without .0 decimal
                if cage.target == math.floor(cage.target) then
                    target_text = tostring(math.floor(cage.target))
                else
                    target_text = tostring(cage.target)
                end
            else
                target_text = tostring(cage.target)
            end
            
            if cage.operation ~= "=" then
                target_text = target_text .. cage.operation
            end
            
            -- Check if this cage's first cell is selected for highlighting
            local is_selected = (first_cell[1] == selected_cell.x and first_cell[2] == selected_cell.y)
            
            -- Draw target text in smaller font
            gfx.setFont(self.small_font)
            
            if is_selected then
                gfx.setImageDrawMode(gfx.kDrawModeInverted)
            end
            
            gfx.drawText(target_text, screen_x, screen_y)
            
            if is_selected then
                gfx.setImageDrawMode(gfx.kDrawModeCopy)
            end
            
            -- Reset to default font
            gfx.setFont(gfx.getFont())
        end
    end
end

function GameUI:draw_completion_popup(completion_time)
    -- Draw popup box (smaller size)
    local popup_width = 200
    local popup_height = 80
    local popup_x = (400 - popup_width) / 2
    local popup_y = (240 - popup_height) / 2
    
    -- Draw popup background
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(popup_x, popup_y, popup_width, popup_height)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(popup_x, popup_y, popup_width, popup_height)
    
    -- Format completion time
    local elapsed_seconds = math.floor(completion_time / 1000)
    local minutes = math.floor(elapsed_seconds / 60)
    local seconds = elapsed_seconds % 60
    local time_text = string.format("%02d:%02d", minutes, seconds)
    
    -- Use system font for all text in compact popup
    local system_font = gfx.getSystemFont()
    gfx.setFont(system_font)
    
    local title = "Completed!"
    local title_width = system_font:getTextWidth(title)
    gfx.drawText(title, popup_x + (popup_width - title_width) / 2, popup_y + 10)
    
    local time_label = "Time: " .. time_text
    local time_label_width = system_font:getTextWidth(time_label)
    gfx.drawText(time_label, popup_x + (popup_width - time_label_width) / 2, popup_y + 30)
    
    local button_text = "Ⓐ New Game"
    local button_text_width = system_font:getTextWidth(button_text)
    gfx.drawText(button_text, popup_x + (popup_width - button_text_width) / 2, popup_y + 50)
end