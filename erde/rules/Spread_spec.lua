-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Spread.parse', function()
  -- TODO
  spec('ruleName', function()
    assert.are.equal('Spread', parse.Spread('...x').ruleName)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Spread.compile', function()
  spec('table spread', function()
    assert.run(
      21,
      compile.Block([[
        local a = { 3, 4, 5 }
        local function sum(t) {
          local answer = 0
          for i, value in ipairs(t) {
            answer += value
          }
          return answer
        }
        return sum({ 1, 2, ...a, 6 })
      ]])
    )
  end)
  spec('function spread', function()
    assert.run(
      12,
      compile.Block([[
        local a = { 3, 4, 5 }
        local function sum(x, y, z) {
          return x + y + z
        }
        return sum(...a)
      ]])
    )
  end)
end)
