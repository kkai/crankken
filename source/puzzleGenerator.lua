local pd <const> = playdate

class("PuzzleGenerator").extends()

function PuzzleGenerator:init()
    math.randomseed(pd.getSecondsSinceEpoch())
end

function PuzzleGenerator:generatePuzzle(size)
    local puzzle = {
        size = size,
        solution = {},
        cages = {}
    }
    
    -- Generate a valid Latin square solution
    puzzle.solution = self:generateLatinSquare(size)
    
    -- Create cages from the solution
    puzzle.cages = self:generateCages(puzzle.solution, size)
    
    return puzzle
end

function PuzzleGenerator:generateLatinSquare(size)
    local grid = {}
    
    -- Initialize empty grid
    for x = 1, size do
        grid[x] = {}
        for y = 1, size do
            grid[x][y] = 0
        end
    end
    
    -- Fill the grid using backtracking
    if self:fillLatinSquare(grid, 1, 1, size) then
        return grid
    else
        -- Fallback to a simple pattern if backtracking fails
        return self:generateSimplePattern(size)
    end
end

function PuzzleGenerator:fillLatinSquare(grid, x, y, size)
    if y > size then
        return true -- Successfully filled the grid
    end
    
    local nextX, nextY = x + 1, y
    if nextX > size then
        nextX, nextY = 1, y + 1
    end
    
    -- Try each number from 1 to size
    local numbers = {}
    for i = 1, size do
        table.insert(numbers, i)
    end
    
    -- Shuffle the numbers for randomness
    for i = #numbers, 2, -1 do
        local j = math.random(i)
        numbers[i], numbers[j] = numbers[j], numbers[i]
    end
    
    for _, num in ipairs(numbers) do
        if self:isValidPlacement(grid, x, y, num, size) then
            grid[x][y] = num
            if self:fillLatinSquare(grid, nextX, nextY, size) then
                return true
            end
            grid[x][y] = 0
        end
    end
    
    return false
end

function PuzzleGenerator:isValidPlacement(grid, x, y, num, size)
    -- Check row constraint
    for i = 1, size do
        if i ~= x and grid[i][y] == num then
            return false
        end
    end
    
    -- Check column constraint
    for i = 1, size do
        if i ~= y and grid[x][i] == num then
            return false
        end
    end
    
    return true
end

function PuzzleGenerator:generateSimplePattern(size)
    local grid = {}
    for x = 1, size do
        grid[x] = {}
        for y = 1, size do
            grid[x][y] = ((x + y - 2) % size) + 1
        end
    end
    return grid
end

function PuzzleGenerator:generateCages(solution, size)
    local cages = {}
    local used = {}
    
    -- Initialize used grid
    for x = 1, size do
        used[x] = {}
        for y = 1, size do
            used[x][y] = false
        end
    end
    
    -- Create cages
    for x = 1, size do
        for y = 1, size do
            if not used[x][y] then
                local cage = self:createCage(solution, used, x, y, size)
                if cage then
                    table.insert(cages, cage)
                end
            end
        end
    end
    
    return cages
end

function PuzzleGenerator:createCage(solution, used, startX, startY, size)
    local cells = {{startX, startY}}
    used[startX][startY] = true
    
    -- Randomly decide cage size (1-4 cells)
    local maxCageSize = math.min(4, math.random(1, 3))
    
    -- Try to add adjacent cells
    while #cells < maxCageSize do
        local added = false
        local lastCell = cells[#cells]
        local directions = {
            {0, 1}, {0, -1}, {1, 0}, {-1, 0}
        }
        
        -- Shuffle directions
        for i = #directions, 2, -1 do
            local j = math.random(i)
            directions[i], directions[j] = directions[j], directions[i]
        end
        
        for _, dir in ipairs(directions) do
            local newX = lastCell[1] + dir[1]
            local newY = lastCell[2] + dir[2]
            
            if newX >= 1 and newX <= size and newY >= 1 and newY <= size 
               and not used[newX][newY] then
                table.insert(cells, {newX, newY})
                used[newX][newY] = true
                added = true
                break
            end
        end
        
        if not added then
            break
        end
    end
    
    -- Calculate cage operation and target
    local values = {}
    for _, cell in ipairs(cells) do
        table.insert(values, solution[cell[1]][cell[2]])
    end
    
    return self:determineCageOperation(cells, values)
end

function PuzzleGenerator:determineCageOperation(cells, values)
    if #cells == 1 then
        return {
            cells = cells,
            operation = "=",
            target = values[1]
        }
    elseif #cells == 2 then
        local operations = {"+", "-", "*", "/"}
        local op = operations[math.random(#operations)]
        
        if op == "+" then
            return {
                cells = cells,
                operation = "+",
                target = values[1] + values[2]
            }
        elseif op == "-" then
            return {
                cells = cells,
                operation = "-",
                target = math.abs(values[1] - values[2])
            }
        elseif op == "*" then
            return {
                cells = cells,
                operation = "x",
                target = values[1] * values[2]
            }
        elseif op == "/" then
            local max_val = math.max(values[1], values[2])
            local min_val = math.min(values[1], values[2])
            if min_val > 0 and max_val % min_val == 0 then
                return {
                    cells = cells,
                    operation = "/",
                    target = max_val / min_val
                }
            else
                -- Fallback to addition if division doesn't work
                return {
                    cells = cells,
                    operation = "+",
                    target = values[1] + values[2]
                }
            end
        end
    else
        -- For larger cages, use addition or multiplication
        local op = math.random(2) == 1 and "+" or "x"
        
        if op == "+" then
            local sum = 0
            for _, v in ipairs(values) do
                sum = sum + v
            end
            return {
                cells = cells,
                operation = "+",
                target = sum
            }
        else
            local product = 1
            for _, v in ipairs(values) do
                product = product * v
            end
            return {
                cells = cells,
                operation = "x",
                target = product
            }
        end
    end
end