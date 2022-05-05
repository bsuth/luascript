describe('Newlines', function()
  spec('statement newlines', function()
    assert.formatted(
      [[
break

break
]],
      [[
break

break
]]
    )
  end)
  spec('comment newlines', function()
    assert.formatted(
      [[
break

-- hello
break
]],
      [[
break

-- hello
break
]]
    )
  end)
  spec('comment + statement newlines', function()
    assert.formatted(
      [[
break

-- hello

break
]],
      [[
break

-- hello

break
]]
    )
  end)
end)

describe('Comments', function()
  spec('leading comments', function()
    assert.formatted(
      [[
-- a
break
]],
      [[
-- a
break
]]
    )
  end)
  spec('trailing comments', function()
    assert.formatted(
      [[
break
-- a
]],
      [[
break
-- a
]]
    )
  end)
  spec('inline comments', function()
    assert.formatted(
      [[
break -- a
]],
      [[
break -- a
]]
    )
  end)
  spec('orphaned comments', function()
    assert.formatted(
      [[
do --a
{   --c
  break --test2
}
]],
      [[
-- a
do { -- c
  break -- test2
}
]]
    )
  end)
end)
