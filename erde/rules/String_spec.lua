-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('String.parse', function()
  spec('rule', function()
    assert.are.equal('String', unit.String('""').rule)
  end)

  spec('short string', function()
    assert.are.equal('"hello"', unit.String('"hello"').value)
    assert.are.equal("'hello'", unit.String("'hello'").value)
    assert.are.equal("'hello\\nworld'", unit.String("'hello\\nworld'").value)
    assert.are.equal("'\\\\'", unit.String("'\\\\'").value)
    assert.has_error(function()
      unit.String('"hello')
    end)
    assert.has_error(function()
      unit.String('"hello\nworld"')
    end)
  end)

  spec('long string', function()
    assert.has_subtable({ 'hello world' }, unit.String('`hello world`'))
    assert.has_subtable({ 'hello\nworld' }, unit.String('`hello\nworld`'))
    assert.has_subtable({ 'a{bc}d' }, unit.String('`a\\{bc}d`'))
    assert.has_subtable({ 'a`b' }, unit.String('`a\\`b`'))
    assert.has_subtable(
      { 'hello ', { value = '3' } },
      unit.String('`hello {3}`')
    )
    assert.has_error(function()
      unit.String('`hello world')
    end)
    assert.has_error(function()
      unit.String('`hello world {2`')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('String.compile', function()
  -- TODO
end)
