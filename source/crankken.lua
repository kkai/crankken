import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/ui"
import "puzzleGenerator"

local pd <const> = playdate
local gfx <const> = pd.graphics

class("CrankKen").extends()

-- Game states
local STATE_SIZE_SELECTION = 1
local STATE_PLAYING = 2
local STATE_COMPLETED = 3

function CrankKen:init()
    self.state = STATE_SIZE_SELECTION
    self.selectedSize = 4
    self.puzzle = nil
    self.playerGrid = nil
    self.selectedCell = {x = 1, y = 1}
    self.cellSize = 33
    self.puzzleGenerator = PuzzleGenerator()
    
    -- Crank tracking variables
    self.lastCrankPosition = pd.getCrankPosition()
    self.crankAccumulator = 0
    
    -- Crank tracking for size selection
    self.sizeCrankAccumulator = 0
    
    -- Load Mini Sans font for cage targets
    self.smallFont = gfx.font.new("fonts/Mini Sans")
end

function CrankKen:showSizeSelection()
    self.state = STATE_SIZE_SELECTION
    gfx.clear()
    
    -- Use system font for bigger title
    local systemFont = gfx.getSystemFont()
    gfx.setFont(systemFont)
    
    -- Draw title left aligned with bold effect (draw twice with slight offset)
    gfx.drawText("CrankKen", 50, 20)
    gfx.drawText("CrankKen", 51, 20)
    
    -- Use smaller font for "Select Size"
    local font = gfx.getFont()
    gfx.setFont(font)
    gfx.drawText("Select Size", 50, 50)
    
    local sizes = {3, 4, 5, 6}
    for i, size in ipairs(sizes) do
        local y = 80 + (i - 1) * 30
        local text = size .. "x" .. size
        if size == self.selectedSize then
            gfx.fillRect(50, y - 5, 100, 25)
            gfx.setImageDrawMode(gfx.kDrawModeInverted)
        end
        gfx.drawText(text, 60, y)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
    
    gfx.drawText("Ⓐ to start a game", 50, 200)
    gfx.drawText("⬆⬇ Select Size", 200, 200)
    
    -- Draw grid preview on the right
    self:drawGridPreview(self.selectedSize)
end

function CrankKen:drawGridPreview(size)
    -- Calculate cell size to fit within screen bounds
    -- Playdate screen is 400x240, leave margin for 6x6 case
    local maxGridSize = 120  -- Maximum pixels for the grid
    local previewCellSize = math.floor(maxGridSize / size)
    local gridPixelSize = size * previewCellSize
    
    -- Center between selection dialog and end of screen
    local dialogEndX = 150  -- Approximate end of the selection dialog
    local screenEndX = 400  -- Screen width
    local availableWidth = screenEndX - dialogEndX
    local previewStartX = dialogEndX + (availableWidth - gridPixelSize) / 2  -- Center in available space
    local previewStartY = (240 - gridPixelSize) / 2        -- Center vertically on screen
    
    -- Draw grid outline
    gfx.setLineWidth(1)
    for x = 0, size do
        local screenX = previewStartX + x * previewCellSize
        gfx.drawLine(screenX, previewStartY, screenX, previewStartY + size * previewCellSize)
    end
    
    for y = 0, size do
        local screenY = previewStartY + y * previewCellSize
        gfx.drawLine(previewStartX, screenY, previewStartX + size * previewCellSize, screenY)
    end
end

function CrankKen:startGame(size)
    self.state = STATE_PLAYING
    self.puzzle = self:generatePuzzle(size)
    self.playerGrid = {}
    
    -- Calculate centered grid position
    local gridWidth = size * self.cellSize
    local gridHeight = size * self.cellSize
    self.gridOffsetX = (400 - gridWidth) / 2
    self.gridOffsetY = (240 - gridHeight) / 2
    
    -- Initialize empty player grid
    for x = 1, size do
        self.playerGrid[x] = {}
        for y = 1, size do
            self.playerGrid[x][y] = 0
        end
    end
    
    self.selectedCell = {x = 1, y = 1}
end

function CrankKen:generatePuzzle(size)
    return self.puzzleGenerator:generatePuzzle(size)
end

function CrankKen:update()
    if self.state == STATE_SIZE_SELECTION then
        self:updateSizeSelection()
    elseif self.state == STATE_PLAYING then
        self:updateGame()
    elseif self.state == STATE_COMPLETED then
        self:updateCompleted()
    end
end

function CrankKen:updateSizeSelection()
    local sizeChanged = false
    local sizes = {3, 4, 5, 6}
    
    -- Handle button input
    if pd.buttonJustPressed(pd.kButtonUp) then
        for i, size in ipairs(sizes) do
            if size == self.selectedSize and i > 1 then
                self.selectedSize = sizes[i - 1]
                sizeChanged = true
                break
            end
        end
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        for i, size in ipairs(sizes) do
            if size == self.selectedSize and i < #sizes then
                self.selectedSize = sizes[i + 1]
                sizeChanged = true
                break
            end
        end
    end
    
    -- Handle crank input for size selection
    local currentCrankPosition = pd.getCrankPosition()
    local crankDelta = currentCrankPosition - self.lastCrankPosition
    
    -- Handle wraparound at 0/360 degrees
    if crankDelta > 180 then
        crankDelta = crankDelta - 360
    elseif crankDelta < -180 then
        crankDelta = crankDelta + 360
    end
    
    self.sizeCrankAccumulator = self.sizeCrankAccumulator + crankDelta
    self.lastCrankPosition = currentCrankPosition
    
    -- Trigger size change on quarter rotation (90 degrees)
    if math.abs(self.sizeCrankAccumulator) >= 90 then
        local currentIndex = 1
        for i, size in ipairs(sizes) do
            if size == self.selectedSize then
                currentIndex = i
                break
            end
        end
        
        if self.sizeCrankAccumulator >= 90 then
            -- Clockwise rotation - next size
            if currentIndex < #sizes then
                self.selectedSize = sizes[currentIndex + 1]
                sizeChanged = true
            end
            self.sizeCrankAccumulator = self.sizeCrankAccumulator - 90
        elseif self.sizeCrankAccumulator <= -90 then
            -- Counter-clockwise rotation - previous size
            if currentIndex > 1 then
                self.selectedSize = sizes[currentIndex - 1]
                sizeChanged = true
            end
            self.sizeCrankAccumulator = self.sizeCrankAccumulator + 90
        end
    end
    
    if sizeChanged then
        self:showSizeSelection()
    end
    
    if pd.buttonJustPressed(pd.kButtonA) then
        self:startGame(self.selectedSize)
        self:drawGame()
    end
end

function CrankKen:updateGame()
    local moved = false
    
    if pd.buttonJustPressed(pd.kButtonUp) and self.selectedCell.y > 1 then
        self.selectedCell.y -= 1
        moved = true
    elseif pd.buttonJustPressed(pd.kButtonDown) and self.selectedCell.y < self.puzzle.size then
        self.selectedCell.y += 1
        moved = true
    elseif pd.buttonJustPressed(pd.kButtonLeft) and self.selectedCell.x > 1 then
        self.selectedCell.x -= 1
        moved = true
    elseif pd.buttonJustPressed(pd.kButtonRight) and self.selectedCell.x < self.puzzle.size then
        self.selectedCell.x += 1
        moved = true
    end
    
    -- Handle number input with A and B buttons (cycle through 0,1,2,...,size)
    if pd.buttonJustPressed(pd.kButtonA) then
        local currentValue = self.playerGrid[self.selectedCell.x][self.selectedCell.y]
        currentValue = (currentValue + 1) % (self.puzzle.size + 1)
        self.playerGrid[self.selectedCell.x][self.selectedCell.y] = currentValue
        moved = true
    elseif pd.buttonJustPressed(pd.kButtonB) then
        local currentValue = self.playerGrid[self.selectedCell.x][self.selectedCell.y]
        currentValue = currentValue - 1
        if currentValue < 0 then
            currentValue = self.puzzle.size
        end
        self.playerGrid[self.selectedCell.x][self.selectedCell.y] = currentValue
        moved = true
    end
    
    -- Handle crank input for number cycling
    local currentCrankPosition = pd.getCrankPosition()
    local crankDelta = currentCrankPosition - self.lastCrankPosition
    
    -- Handle wraparound at 0/360 degrees
    if crankDelta > 180 then
        crankDelta = crankDelta - 360
    elseif crankDelta < -180 then
        crankDelta = crankDelta + 360
    end
    
    self.crankAccumulator = self.crankAccumulator + crankDelta
    self.lastCrankPosition = currentCrankPosition
    
    -- Trigger number change on half rotation (180 degrees)
    if math.abs(self.crankAccumulator) >= 180 then
        local currentValue = self.playerGrid[self.selectedCell.x][self.selectedCell.y]
        
        if self.crankAccumulator >= 180 then
            -- Clockwise rotation - increment number
            currentValue = (currentValue + 1) % (self.puzzle.size + 1)
            self.crankAccumulator = self.crankAccumulator - 180
        elseif self.crankAccumulator <= -180 then
            -- Counter-clockwise rotation - decrement number
            currentValue = currentValue - 1
            if currentValue < 0 then
                currentValue = self.puzzle.size
            end
            self.crankAccumulator = self.crankAccumulator + 180
        end
        
        self.playerGrid[self.selectedCell.x][self.selectedCell.y] = currentValue
        moved = true
    end
    
    -- Clear cell with menu button
    if pd.buttonJustPressed(pd.kButtonMenu) then
        self.playerGrid[self.selectedCell.x][self.selectedCell.y] = 0
        moved = true
    end
    
    
    if moved then
        self:drawGame()
        if self:checkCompletion() then
            self.state = STATE_COMPLETED
            self:drawCompleted()
        end
    end
end

function CrankKen:drawGame()
    gfx.clear()
    
    
    -- First pass: Draw cage boundaries and backgrounds
    self:drawCageBoundaries()
    
    -- Second pass: Draw grid and numbers
    for x = 1, self.puzzle.size do
        for y = 1, self.puzzle.size do
            local screenX = self.gridOffsetX + (x - 1) * self.cellSize
            local screenY = self.gridOffsetY + (y - 1) * self.cellSize
            
            -- Highlight selected cell
            if x == self.selectedCell.x and y == self.selectedCell.y then
                gfx.fillRect(screenX + 2, screenY + 2, self.cellSize - 4, self.cellSize - 4)
                gfx.setImageDrawMode(gfx.kDrawModeInverted)
            end
            
            -- Draw number if entered
            local value = self.playerGrid[x][y]
            if value > 0 then
                -- Use system font for user input numbers
                local systemFont = gfx.getSystemFont()
                gfx.setFont(systemFont)
                
                local textX = screenX + self.cellSize / 2 - 2
                local textY = screenY + self.cellSize / 2 - 8
                gfx.drawText(tostring(value), textX, textY)
                
                -- Reset to default font
                gfx.setFont(gfx.getFont())
            end
            
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
    end
    
    -- Third pass: Draw cage targets
    self:drawCageTargets()
    
    
end

function CrankKen:drawCageBoundaries()
    gfx.setLineWidth(3)
    
    for _, cage in ipairs(self.puzzle.cages) do
        if #cage.cells > 0 then
            -- Create a set for quick lookup of cells in this cage
            local cellSet = {}
            for _, cell in ipairs(cage.cells) do
                cellSet[cell[1] .. "," .. cell[2]] = true
            end
            
            -- For each cell in the cage, draw thick borders where needed
            for _, cell in ipairs(cage.cells) do
                local x, y = cell[1], cell[2]
                local screenX = self.gridOffsetX + (x - 1) * self.cellSize
                local screenY = self.gridOffsetY + (y - 1) * self.cellSize
                
                -- Check each edge and draw thick border if not connected to same cage
                -- Top edge
                if y == 1 or not cellSet[(x) .. "," .. (y-1)] then
                    gfx.drawLine(screenX, screenY, screenX + self.cellSize, screenY)
                end
                
                -- Bottom edge
                if y == self.puzzle.size or not cellSet[(x) .. "," .. (y+1)] then
                    gfx.drawLine(screenX, screenY + self.cellSize, screenX + self.cellSize, screenY + self.cellSize)
                end
                
                -- Left edge
                if x == 1 or not cellSet[(x-1) .. "," .. (y)] then
                    gfx.drawLine(screenX, screenY, screenX, screenY + self.cellSize)
                end
                
                -- Right edge
                if x == self.puzzle.size or not cellSet[(x+1) .. "," .. (y)] then
                    gfx.drawLine(screenX + self.cellSize, screenY, screenX + self.cellSize, screenY + self.cellSize)
                end
            end
        end
    end
    
    gfx.setLineWidth(1)
end

function CrankKen:drawCageTargets()
    -- Draw cage targets in the top-left corner of the first cell
    for _, cage in ipairs(self.puzzle.cages) do
        if #cage.cells > 0 then
            local firstCell = cage.cells[1]
            local screenX = self.gridOffsetX + (firstCell[1] - 1) * self.cellSize + 3
            local screenY = self.gridOffsetY + (firstCell[2] - 1) * self.cellSize + 3
            
            local targetText
            if cage.operation == "/" then
                -- Format division targets without .0 decimal
                if cage.target == math.floor(cage.target) then
                    targetText = tostring(math.floor(cage.target))
                else
                    targetText = tostring(cage.target)
                end
            else
                targetText = tostring(cage.target)
            end
            
            if cage.operation ~= "=" then
                targetText = targetText .. cage.operation
            end
            
            -- Check if this cage's first cell is selected for highlighting
            local isSelected = (firstCell[1] == self.selectedCell.x and firstCell[2] == self.selectedCell.y)
            
            -- Draw target text in smaller font
            gfx.setFont(self.smallFont)
            
            if isSelected then
                gfx.setImageDrawMode(gfx.kDrawModeInverted)
            end
            
            gfx.drawText(targetText, screenX, screenY)
            
            if isSelected then
                gfx.setImageDrawMode(gfx.kDrawModeCopy)
            end
            
            -- Reset to default font
            gfx.setFont(gfx.getFont())
        end
    end
end

function CrankKen:checkCompletion()
    -- Check if all cells are filled
    for x = 1, self.puzzle.size do
        for y = 1, self.puzzle.size do
            if self.playerGrid[x][y] == 0 then
                return false
            end
        end
    end
    
    -- Check row and column constraints
    for i = 1, self.puzzle.size do
        local rowValues = {}
        local colValues = {}
        for j = 1, self.puzzle.size do
            local rowVal = self.playerGrid[i][j]
            local colVal = self.playerGrid[j][i]
            
            if rowValues[rowVal] or colValues[colVal] then
                return false
            end
            rowValues[rowVal] = true
            colValues[colVal] = true
        end
    end
    
    -- Check cage constraints
    for _, cage in ipairs(self.puzzle.cages) do
        if not self:checkCage(cage) then
            return false
        end
    end
    
    return true
end

function CrankKen:checkCage(cage)
    local values = {}
    for _, cell in ipairs(cage.cells) do
        table.insert(values, self.playerGrid[cell[1]][cell[2]])
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

function CrankKen:updateCompleted()
    if pd.buttonJustPressed(pd.kButtonA) then
        self:showSizeSelection()
    end
end

function CrankKen:drawCompleted()
    gfx.clear()
    
    -- Use system font for completion screen
    local systemFont = gfx.getSystemFont()
    gfx.setFont(systemFont)
    
    local title = "Puzzle Completed!"
    local titleWidth = systemFont:getTextWidth(title)
    gfx.drawText(title, (400 - titleWidth) / 2, 100)
    
    gfx.drawText("Ⓐ New Game", 150, 150)
    
    -- Reset to default font
    gfx.setFont(gfx.getFont())
end