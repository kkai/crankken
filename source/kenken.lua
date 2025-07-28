import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/ui"
import "puzzleGenerator"

local pd <const> = playdate
local gfx <const> = pd.graphics

class("Kenken").extends()

-- Game states
local STATE_SIZE_SELECTION = 1
local STATE_PLAYING = 2
local STATE_COMPLETED = 3

function Kenken:init()
    self.state = STATE_SIZE_SELECTION
    self.selectedSize = 4
    self.puzzle = nil
    self.playerGrid = nil
    self.selectedCell = {x = 1, y = 1}
    self.cellSize = 33
    self.puzzleGenerator = PuzzleGenerator()
end

function Kenken:showSizeSelection()
    self.state = STATE_SIZE_SELECTION
    gfx.clear()
    
    local font = gfx.getFont()
    local title = "Kenken - Select Size"
    local titleWidth = font:getTextWidth(title)
    gfx.drawText(title, (400 - titleWidth) / 2, 30)
    
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
    
    gfx.drawText("🅰 Start Game", 50, 200)
    gfx.drawText("⬆⬇ Select Size", 200, 200)
end

function Kenken:startGame(size)
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

function Kenken:generatePuzzle(size)
    return self.puzzleGenerator:generatePuzzle(size)
end

function Kenken:update()
    if self.state == STATE_SIZE_SELECTION then
        self:updateSizeSelection()
    elseif self.state == STATE_PLAYING then
        self:updateGame()
    elseif self.state == STATE_COMPLETED then
        self:updateCompleted()
    end
end

function Kenken:updateSizeSelection()
    if pd.buttonJustPressed(pd.kButtonUp) then
        local sizes = {3, 4, 5, 6}
        for i, size in ipairs(sizes) do
            if size == self.selectedSize and i > 1 then
                self.selectedSize = sizes[i - 1]
                break
            end
        end
        self:showSizeSelection()
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        local sizes = {3, 4, 5, 6}
        for i, size in ipairs(sizes) do
            if size == self.selectedSize and i < #sizes then
                self.selectedSize = sizes[i + 1]
                break
            end
        end
        self:showSizeSelection()
    elseif pd.buttonJustPressed(pd.kButtonA) then
        self:startGame(self.selectedSize)
        self:drawGame()
    end
end

function Kenken:updateGame()
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
    
    -- Handle number input with A and B buttons
    if pd.buttonJustPressed(pd.kButtonA) then
        local currentValue = self.playerGrid[self.selectedCell.x][self.selectedCell.y]
        currentValue = (currentValue % self.puzzle.size) + 1
        self.playerGrid[self.selectedCell.x][self.selectedCell.y] = currentValue
        moved = true
    elseif pd.buttonJustPressed(pd.kButtonB) then
        local currentValue = self.playerGrid[self.selectedCell.x][self.selectedCell.y]
        currentValue = currentValue - 1
        if currentValue < 1 then
            currentValue = self.puzzle.size
        end
        self.playerGrid[self.selectedCell.x][self.selectedCell.y] = currentValue
        moved = true
    end
    
    -- Clear cell with crank button
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

function Kenken:drawGame()
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
                local textX = screenX + self.cellSize / 2 - 2
                local textY = screenY + self.cellSize / 2 - 8
                gfx.drawText(tostring(value), textX, textY)
            end
            
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
    end
    
    -- Third pass: Draw cage targets
    self:drawCageTargets()
    
end

function Kenken:drawCageBoundaries()
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

function Kenken:drawCageTargets()
    -- Draw cage targets in the top-left corner of the first cell
    for _, cage in ipairs(self.puzzle.cages) do
        if #cage.cells > 0 then
            local firstCell = cage.cells[1]
            local screenX = self.gridOffsetX + (firstCell[1] - 1) * self.cellSize + 3
            local screenY = self.gridOffsetY + (firstCell[2] - 1) * self.cellSize + 3
            
            local targetText = tostring(cage.target)
            if cage.operation ~= "=" then
                targetText = targetText .. cage.operation
            end
            
            -- Draw target text in smaller font at top-left corner
            local smallFont = gfx.getFont(gfx.kFontVariant_Normal)
            gfx.setFont(smallFont)
            gfx.drawText(targetText, screenX, screenY)
            gfx.setFont(gfx.getFont())
        end
    end
end

function Kenken:checkCompletion()
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

function Kenken:checkCage(cage)
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

function Kenken:updateCompleted()
    if pd.buttonJustPressed(pd.kButtonA) then
        self:showSizeSelection()
    end
end

function Kenken:drawCompleted()
    gfx.clear()
    
    local font = gfx.getFont()
    local title = "Puzzle Completed!"
    local titleWidth = font:getTextWidth(title)
    gfx.drawText(title, (400 - titleWidth) / 2, 100)
    
    gfx.drawText("🅰 New Game", 150, 150)
end